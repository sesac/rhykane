# frozen_string_literal: true

require_relative './rhykane/jobs'
require_relative './rhykane/transform'
require_relative './rhykane/s3/get'
require_relative './rhykane/s3/put'

class Rhykane
  class << self
    def call(*deps, **cfg)
      new(*deps, **cfg).()
    end

    def for(job_name, dirname = 'config', client = Aws::S3::Resource.new)
      config_path = Pathname(dirname.to_s).join('rhykane.yml').expand_path

      new(client, **Jobs.load(config_path)[job_name.to_sym])
    end
  end

  def initialize(client = Aws::S3::Resource.new, **cfg)
    @client                            = client
    @transforms, @source, @destination = Config.new.(cfg).values_at(:transforms, :source, :destination)
  end

  def call
    IO.pipe do |rd, wr|
      wr_thread = Thread.new { S3::Put.(client, rd, **destination) }

      S3::Get.(client, **source) do |rd_stream|
        Transform.(rd_stream, wr, transforms:, source:, destination:)
      end
      wr_thread.join
    end
  end

  private

  attr_reader :client, :transforms, :source, :destination
end
