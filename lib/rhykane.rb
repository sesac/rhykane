# frozen_string_literal: true

require_relative 'rhykane/jobs'
require_relative 'rhykane/reader'
require_relative 'rhykane/writer'
require_relative 'rhykane/transform'
require_relative 'rhykane/s3/get'
require_relative 'rhykane/s3/put'

class Rhykane
  class << self
    def call(...)
      new(...).()
    end

    def for(job_name, dirname = 'config', client = Aws::S3::Resource.new)
      config_path = Pathname(dirname.to_s).join('rhykane.yml').expand_path

      new(client, **Jobs.load(config_path)[job_name.to_sym])
    end
  end

  def initialize(client = Aws::S3::Resource.new, **, &block)
    @client, @work, @config = client, block, Config.new.(**)
  end

  def call = IO.pipe do |rd, wr| transform_pipe(wr, rd) end

  private

  attr_reader :client, :work, :config

  def transform_pipe(wr_io, rd_io)
    output_thread = new_output_thread(rd_io)

    transform_input(wr_io)
  rescue StandardError, SignalException
    output_thread.kill
    raise
  ensure
    wr_io.close unless wr_io.closed?
    output_thread.join
  end

  def new_output_thread(rdr)
    Thread.new {
      Thread.current.abort_on_exception = true
      S3::Put.(client, rdr, **destination)
    }
  end

  def transform_input(wr_io) = input_stream do |inpt| transform(inpt, wr_io) end
  def transform(inpt, wr_io) = Transform.(new_reader(inpt), new_writer(wr_io), **transforms, &work)
  def input_stream(&)        = S3::Get.(client, **source, &)
  def new_reader(input)      = Reader.(input, **source)
  def new_writer(io)         = Writer.(io, **destination)
  def source                 = config[:source]
  def destination            = config[:destination]
  def transforms             = config[:transforms]
end
