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

    def self.call(enum, **, &) = new(**, &).(enum)

    def initialize(row: [], values: {}, **, &block)
      val_fns = values.transform_values { |val| pipeline(val) }
      @row_fn = pipeline(block) >> pipeline(row) >> self.class[:transform_values, val_fns]
    end

    def call(enum) = Stream.(enum, row_fn)

    class Stream
      def self.call(enum, transform) = new(enum, transform)

      def initialize(enum, transform)
        @enum      = enum
        @transform = transform
      end

      def each
        return enum_for(__method__) unless block_given?

        enum.each do |row|
          yield transform.(row)
        end
      end

      private

      attr_reader :enum, :transform
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
