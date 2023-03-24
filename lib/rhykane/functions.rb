# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'

class Functions
  class << self
    def to_json(value)
      JSON.dump(value) unless value.nil?
    end

    def parse_period(value, op)
      return if value.nil?

      date = Date.strptime(value, '%d%m%y')
      op == :start ? date.beginning_of_month.strftime("%Y-%m-%d") : date.end_of_month.strftime("%Y-%m-%d")
    end
  end
end
