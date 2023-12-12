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
        def call(*deps, **args, &)
          klass(**args).new(*deps, **args).(&)
        end

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

      class Stream < Get
      end

      class Unzip < Get
        private

        def read
          skip_first = true
          ::Zip::File.open_buffer(object.get.body) do |zip_file|
            zip_file.each do |entry|
              skip_first || yield(zip_file.read(entry))
              skip_first = false
            end
          end
        end
      end

      class Ungzip < Get
        private

        def read
          Zlib::GzipReader.wrap(object.get.body) do |gz|
            while (line = gz.gets)
              yield line
            end
          end
        end
      end
    end
  end
end
