# frozen_string_literal: true

require 'aws-sdk-s3'
require 'zip'
require 'stringio'
require 'zlib'
require 'rubygems/package'

class Rhykane
  module S3
    class Get
      DECOMPRESSION_STRATEGIES = Hash.new('stream').merge(zip: 'unzip', gz: 'ungzip').freeze

      class << self
        def call(*deps, **args, &) = klass(**args).new(*deps, **args).(&)

        def klass(key:, extension: Pathname(key).extname.delete('.').to_sym, **)
          const_get(DECOMPRESSION_STRATEGIES[extension].capitalize)
        end
      end

      def initialize(client = Aws::S3::Resource.new, bucket:, key:, **opts)
        @object, @opts = client.bucket(bucket).object(key), opts
      end

      def call(&) = IO.pipe do |rd, wr| stream(rd, wr, &) end

      private

      attr_reader :object, :opts

      def stream(rd_io, wr_io, &)
        output_thread = new_pipe_thread(rd_io, &)

        read(wr_io)
      rescue StandardError, SignalException
        output_thread.kill
        raise
      ensure
        wr_io.close unless wr_io.closed?
        output_thread.join
      end

      def new_pipe_thread(pipe)
        Thread.new {
          Thread.current.abort_on_exception = true
          yield pipe
        }
      end

      def read(wr_io) = object.get do |chunk, *| wr_io << chunk end

      class Stream < Get; end

      class Unzip < Get
        private

        def read(wr_io) = get do |file| stream_zip(file, wr_io) end

        def get
          Tempfile.create(filename_parts) do |response_target|
            object.get(response_target:)
            yield response_target
          end
        end

        def filename_parts
          filename = Pathname(object.key).basename
          extname  = filename.extname

          [filename.to_s.split(extname), extname].flatten
        end

        def stream_zip(zip, wr_io)
          if decrypter
            new_zip_stream(zip) do |zip_file| stream_pw_entries(zip_file, wr_io) end
          else
            ::Zip::File.open_buffer(zip) do |zip_file| stream_entries(zip_file, wr_io) end
          end
        end
        
        def new_zip_stream(zip, &) = ::Zip::InputStream.open(zip, 0, decrypter, &)
        def decrypter              = (pwd = opts[:password]) && Zip::TraditionalDecrypter.new(pwd)

        ENTRY_EXCLUDE_PATTERN = /(__MACOSX|\.DS_Store)/
        ARCHIVE_GLOB_PATTERN = '{[!__MAC*]*,[!*DS_Store*],*}'

        def stream_pw_entries(input_io, wr_io)
          return_header = true
          while (entry = input_io.get_next_entry)
            next if entry.name.match?(self.class::ENTRY_EXCLUDE_PATTERN)

            header = input_io.readline
            wr_io << header if return_header
            return_header = false
            IO.copy_stream(input_io, wr_io)
          end
        end

        def stream_entries(entries, wr_io)
          return_header = true
          entries.glob(ARCHIVE_GLOB_PATTERN).map(&:get_input_stream).each do |io|
            header = io.readline
            wr_io << header if return_header
            return_header = false
            IO.copy_stream(io, wr_io)
          end
        end
      end

      class Ungzip < Unzip
        private

        UNZIPPER = Zlib::GzipReader

        def read(wr_io)            = get do |file| stream_zip(file, wr_io) end
        def stream_zip(zip, wr_io) = self.class::UNZIPPER.wrap(zip) do |gz| IO.copy_stream(gz, wr_io) end
      end
    end
  end
end
