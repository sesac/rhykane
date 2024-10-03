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

      def initialize(client = Aws::S3::Resource.new, bucket:, key:, **)
        @object = client.bucket(bucket).object(key)
      end

      def call
        IO.pipe do |rd, wr|
          read_thread = get_thread(wr)
          yield rd
          read_thread.join
        end
      end

      private

      attr_reader :object

      def get_thread(pipe)
        Thread.new {
          read do |chunk| pipe << chunk end
          pipe.close
        }
      end

      def read
        object.get do |chunk, *| yield chunk end
      end

      class Stream < Get; end

      class Unzip < Get
        private

        def read(&block)
          return_header = true
          get do |file|
            ::Zip::File.open_buffer(file) do |zip_file|
              zip_file.map(&:get_input_stream).each do |io|
                header = io.readline
                yield header if return_header
                return_header = false
                io.each(&block)
              end
            end
          end
        end

        def get
          filename = Pathname(object.key).basename
          extname  = filename.extname
          pfx, ext = [filename.to_s.split(extname), extname].flatten
          Tempfile.create([pfx, ext]) do |response_target|
            object.get(response_target:)
            yield response_target
          end
        end
      end

      class Ungzip < Unzip
        private

        def read(&)
          get do |file|
            Zlib::GzipReader.wrap(file) do |gz|
              gz.each(&)
            end
          end
        end
      end
    end
  end
end
