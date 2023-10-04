# frozen_string_literal: true

require 'aws-sdk-s3'
require 'zip'
require 'zlib'
require 'stringio'
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
          # puts "hi"
          # binding.pry
          ::Zip::File.open_buffer(object.get.body) do |zip_file|
            zip_file.each do |entry|
              yield zip_file.read(entry)
            end
          end
        end
      end

      class Ungzip < Get
      private

        def read
          # binding.pry
          gzip_data = object.get.body.string
          Zlib::GzipReader.wrap(StringIO.new(gzip_data)) do |gz|
            gz.each_line do |line|
              yield line.chomp 
            end
          end
        end

        # def read_2
        #   gzip_data = object.get.body.string
        #   Zlib::GzipReader.wrap(StringIO.new(gzip_data)) do |gz|
        #     tar = Gem::Package::TarReader.new(gz)
        #     extracted_directory = 'tmp/'
        #     Dir.mkdir(extracted_directory) unless Dir.exist?(extracted_directory)
        #     tar.each do |entry|
        #       entry_path = File.join(extracted_directory, entry.full_name)
        #       if entry.directory?
        #         FileUtils.mkdir_p(entry_path)
        #       else
        #         File.open(entry_path, 'wb') { |file| file.write(entry.read) }
        #       end
        #     end
        #     puts "Files extracted to #{extracted_directory}"
        #   end
        # end

        # def read_1
        #   # puts "hi"
        #   # Zlib::GzipReader.open_buffer(object.get.body) do |gz|
        #   # Zlib::GzipReader.new(object.get.body) do |gz|
        #   gzip_data = object.get.body.string
        #   Zlib::GzipReader.wrap(StringIO.new(gzip_data)) do |gz|
        #   binding.pry
        #     return untar(gz) if gz.path.include?('.tar')
        #     local_copy = Pathname(gz.path.chomp('.gz'))
        #     local_copy.open('w') do |file| gz.each(&file.method(:puts)) end
        #     send_to_s3(local_copy)
        #     local_copy.delete
        #   end
        # end
      end
      # ---------
    end
  end
end
