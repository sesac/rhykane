# frozen_string_literal: true

require 'active_support/core_ext/date/calculations'

module Functions
  def to_json(value)
    JSON.dump(value) unless value.nil?
  end

  def parse_period(value, args)
    return if value.nil?

    date, day = get_day(value, **args)
    return create_date(date, day) unless args[:quarter_type]

    qtr_args = { type: args[:type], date:, day: }
    args[:quarter_type] == :ordinal ? ordinal_qtr(**qtr_args) : numeric_qtr(**qtr_args)
  end

  def get_day(value, date_format:, type:, **)
    date = Date.strptime(value, date_format)
    day  = type == :start ? 1 : -1
    [date, day]
  end

  def create_date(date, day, month = nil)
    month ||= date.month
    Date.new(date.year, month, day).to_s
  end

  def ordinal_qtr(type:, date:, day:)
    month = type == :start ? (date.month * 3) - 2 : date.month * 3
    create_date(date, day, month)
  end

  def numeric_qtr(type:, date:, day:)
    month = type == :start ? date.month - 2 : date.month
    create_date(date, day, month)
  end

  def seconds_to_iso(original)
    duration = ActiveSupport::Duration.build(original.to_f.round)
    duration.iso8601
  end

  def military_to_iso(original)
    parts   = original.split(':').map(&:to_i)
    h, m, s = parts[-3] || 0, parts[-2], parts[-1]

    "PT#{h}H#{m}M#{s}S"
  end

  def upcase(original)
    original.upcase
  end

  def split(original)
    original.split(' ').first
  end
end
