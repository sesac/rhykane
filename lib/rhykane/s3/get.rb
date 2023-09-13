# frozen_string_literal: true

require 'aws-sdk-s3'
# require 'open3'
require 'zip'

class Rhykane
  module S3

    class Get
      DECOMPRESSION_STRATEGIES = Hash.new('stream').merge( zip: 'unzip' ).freeze

      class << self
        def call(*deps, **args, &)
          klass(**args).new(*deps, **args).(&)
        end

        def klass(key:, extension: Pathname(key).extname.delete('.').to_sym, **)
          const_get(DECOMPRESSION_STRATEGIES[extension].capitalize)
        rescue NameError
          self
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
          read do |chunk|
            pipe << chunk
          end
          pipe.close
        }
      end

      def read
        object.get do |chunk, *| yield chunk end
      end

      class Stream < Get
      end

      class Unzip < Get

        def initialize(client = Aws::S3::Resource.new, bucket:, key:, type:, **)
          super

          @key_path   = Pathname(key)
          @tmp_root   = Pathname(ENV.fetch('TMP_ROOT', '/mnt/tmp'))
          @local_path = @tmp_root.join(key_path)
          @type       = type
        end

        def call
          local_path.dirname.mkpath
          object.download_file(local_path)
          super
        ensure
          local_path.delete if local_path.exist?
        end

        private

        attr_reader :local_path, :key_path, :type

        def read
          ::Zip::File.open(local_path) do |zip_file|
            zip_file.map do |entry|
              zip_file.get_input_stream(entry)
            end
          end.flatten.each do |io|
            yield io.read
          end
        end
      end
    end
  end
end
