# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

module Functions
  def to_json(value)
    JSON.dump(value) unless value.nil?
  end

  def parse_period(value, range)
    return if value.nil?

    date = Date.strptime(value, '%d%m%y')
    range == :start ? date.beginning_of_month.strftime('%Y-%m-%d') : date.end_of_month.strftime('%Y-%m-%d')
  end
end
