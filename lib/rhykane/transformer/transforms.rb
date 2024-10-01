# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/date/calculations'

class Rhykane
  class Transformer
    module Transforms
      # def t(...)
      #   Transforms.t(...)
      # end

      def self.transform_values(row, transforms)
        transforms.each do |key, transform| row[key] = transform.(row[key]) end

        row
      end

      def self.nest(row, (key, vals))
        Dry::Transformer::HashTransformations.nest(row, key, vals)
      end

      def self.set_default(row, default) = row.to_h.tap { |this| default.each { |key, val| this[key] ||= val } }

      def self.as_json(value) = (value and JSON.dump(value))

      def self.upcase(original) = original&.upcase

      def self.split(original) = original&.split&.first

      def self.parse_period(value, args)
        return unless value

        date, day = get_day(value, **args)
        return create_date(date, day) unless args[:quarter_type]

        qtr_args = { type: args[:type], date:, day: }

        args[:quarter_type] == :ordinal ? ordinal_qtr(**qtr_args) : numeric_qtr(**qtr_args)
      end

      def self.get_day(value, date_format:, type:, **)
        date = Date.strptime(value, date_format)

        [date, type == :start ? 1 : -1]
      end

      def self.create_date(date, day, month = nil)
        month ||= date.month

        Date.new(date.year, month, day).to_s
      end

      def self.ordinal_qtr(type:, date:, day:)
        month = type == :start ? (date.month * 3) - 2 : date.month * 3

        create_date(date, day, month)
      end

      def self.numeric_qtr(type:, date:, day:)
        month = type == :start ? date.month - 2 : date.month

        create_date(date, day, month)
      end

      def self.seconds_to_iso(original) = ActiveSupport::Duration.build(original.to_f.round).iso8601

      def self.military_to_iso(original)
        parts   = original.split(':').map(&:to_i)
        h, m, s = parts[-3] || 0, parts[-2], parts[-1]

        "PT#{h}H#{m}M#{s}S"
      end
    end
  end
end
