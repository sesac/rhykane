# frozen_string_literal: true

require 'dry/transformer'
require 'dry/inflector'
require_relative 'transformer/transforms'

class Rhykane
  class Transformer
    extend Dry::Transformer::Registry

    import Dry::Transformer::Coercions
    import Dry::Transformer::Conditional
    import Dry::Transformer::HashTransformations
    import Dry::Transformer::ArrayTransformations
    import Transforms

    class << self
      def call(io, **, &) = new(**, &).(io)
    end

    def initialize(row: [], values: {}, **, &block)
      val_fns = values.transform_values { |val| pipeline(val) }
      @row_fn = pipeline(block) >> pipeline(row) >> self.class[:transform_values, val_fns]
    end

    def call(io) = Stream.(io, row_fn)

    class Stream
      def self.call(io, transform) = new(io, transform)

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
