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

      def call(input_io)
        binding.pry
        object.upload_stream do |stream|
          IO.copy_stream(input_io, stream)
          # binding.pry
        end
      end
    end
  end
end
