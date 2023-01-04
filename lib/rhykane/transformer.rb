# frozen_string_literal: true

require 'dry/transformer'
require 'dry/transformer/hash_transformations'

module Rhykane
  class Transformer
    extend Dry::Transformer::Registry
    import Dry::Transformer::Coercions
    import Dry::Transformer::HashTransformations

    class << self
      def call(io, **cfg)
        new(**cfg).(io)
      end

      def transform_values(row, transforms)
        transforms.each do |key, transform| row[key] = transform.(row[key]) end

        row
      end

      def identity(this, *)
        this
      end
    end

    def initialize(transforms:, **)
      fn      = pipeline(transforms.fetch(:row, []))
      val_fns = transforms.fetch(:values, {}).transform_values(&method(:pipeline))
      @row_fn = fn.>>(self.class[:transform_values, val_fns])
    end

    def call(io)
      Stream.(io, row_fn)
    end

    class Stream
      def self.call(io, transform)
        new(io, transform)
      end

      def initialize(io, transform)
        @io        = io
        @transform = transform
      end

      def each
        return enum_for(__method__) unless block_given?

        io.each do |row|
          yield transform.(row)
        end
      end

      private

      attr_reader :io, :transform
    end

    private

    attr_reader :row_fn

    def pipeline(dfns)
      Array(dfns).then { |defs|
        defs.empty? ? [%i[identity]] : defs
      }.each_with_object(self.class).map { |args, reg| reg[*args] }.reduce(:>>)
    end
  end
end
