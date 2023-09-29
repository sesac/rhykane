# frozen_string_literal: true

require 'active_support/core_ext/date/calculations'

module Functions
  def to_json(value)
    JSON.dump(value) unless value.nil?
  end

  def parse_period(value, args)
    return if value.nil?

    type, date_format, quarter_type = args.values_at(:type, :date_format, :quarter_type)
    date = Date.strptime(value, date_format)
    day  = type == :start ? 1 : -1
    return Date.new(date.year, date.month, day).to_s if quarter_type.nil?

    quarter_args = { type: type, date: date, day: day }
    quarter_type == :ordinal ? ordinal_quarter(**quarter_args) : numeric_quarter(**quarter_args)
  end

  def ordinal_quarter(type:, date:, day:)
    month = type == :start ? (date.month * 3) - 2 : date.month * 3
    Date.new(date.year, month, day).to_s
  end

  def numeric_quarter(type:, date:, day:)
    month = type == :start ? date.month - 2 : date.month
    Date.new(date.year, month, day).to_s
  end

  def seconds_to_iso(original)
    rounded  = original.to_f.round
    duration = ActiveSupport::Duration.build(rounded)
    h = duration.parts[:hours]   || 0
    m = duration.parts[:minutes] || 0
    s = duration.parts[:seconds] || 0

    "PT#{h}H#{m}M#{s}S"
  end

  def military_to_iso(original)
    parts = original.split(':').map(&:to_i)
    h, m, s = parts[-3] || 0, parts[-2], parts[-1]

    "PT#{h}H#{m}M#{s}S"
  end
end
