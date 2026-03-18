# frozen_string_literal: true

require_relative 'get'

class Rhykane
  module S3
    class Put < Get
      class << self
        def call(*deps, **args)
          *rest, io = *deps

          new(*rest, **args).(io)
        end
      end

      def initialize(client = Aws::S3::Resource.new, bucket:, key:, source_bucket:, source_key:, **opts)
        @opts = opts
        @source_object      = client.bucket(source_bucket).object(source_key)
        @destination_object = client.bucket(bucket).object(key)
      end

      def call(input_io) = destination_object.upload_stream(part_size:) do |stream| IO.copy_stream(input_io, stream) end

      private

      attr_reader :opts, :source_object, :destination_object

      def part_size
        max_s3_parts      = 10_000
        default_part_size = 5 * 1024 * 1024 # 5 MiB
        calculated_size   = (source_object.content_length.fdiv(max_s3_parts)).ceil

        [default_part_size, calculated_size].max
      end
    end
  end
end
