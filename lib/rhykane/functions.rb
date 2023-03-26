# frozen_string_literal: true

module Functions
  def to_json(value)
    JSON.dump(value) unless value.nil?
  end

  def parse_period(value, type)
    return if value.nil?

    date = Date.strptime(value.slice(2..-1), '%m%y')
    day = type == :start ? 1 : -1
    Date.new(date.year, date.month, day).to_s
  end
end
