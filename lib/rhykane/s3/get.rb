# frozen_string_literal: true

require 'aws-sdk-s3'

module Rhykane
  module S3
    class Get
      class << self
        def call(*deps, **args, &)
          new(*deps, **args).(&)
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
          object.get do |chunk, *| pipe << chunk end
          pipe.close
        }
      end
    end
  end
end
