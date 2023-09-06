# frozen_string_literal: true

module Functions
  def to_json(value)
    JSON.dump(value) unless value.nil?
  end

  def parse_period(value, args)
    return if value.nil?

    type, date_format, quarter_type = args.values_at(:type, :date_format, :quarter_type)
    date = Date.strptime(value, date_format)
    day = type == :start ? 1 : -1
    return Date.new(date.year, date.month, day).to_s if !quarter_type
    quarterly_format(quarter_type, type, date, day)
  end

  def quarterly_format(quarter_type, type, date, day)
    if quarter_type == :ordinal
      month = type == :start ? date.month * 3 - 2 : date.month * 3
    else
      month = type == :start ? date.month - 2 : date.month
    end
    Date.new(date.year, month, day).to_s
  end

  def seconds_to_iso(original)
    rounded  = original.to_f.round
    duration = ActiveSupport::Duration.build(rounded)
    hours    = duration.parts[:hours]   || 0
    minutes  = duration.parts[:minutes] || 0
    seconds  = duration.parts[:seconds] || 0

    "PT#{hours}H#{minutes}M#{seconds}S"
  end

  def military_to_iso(original)
    parts = original.split(':').map(&:to_i)
    hours, minutes, seconds = parts[-3] || 0, parts[-2], parts[-1]

    "PT#{hours}H#{minutes}M#{seconds}S"
  end
end
