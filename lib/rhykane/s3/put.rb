# frozen_string_literal: true

require_relative 'get'

class Rhykane
  module S3
    class Put < Get
      PART_SIZE = 30 * 1024 * 1024 # 30 MiB

      class << self
        def call(*deps, **args)
          *rest, io = *deps

          new(*rest, **args).(io)
        end
      end

      def call(input_io) = object.upload_stream(part_size: PART_SIZE) do |stream| IO.copy_stream(input_io, stream) end
    end
  end
end
