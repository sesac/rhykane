# frozen_string_literal: true

require 'simplecov'
require 'simplecov-html'
require 'simplecov_json_formatter'

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                  SimpleCov::Formatter::HTMLFormatter,
                                                                  SimpleCov::Formatter::JSONFormatter
                                                                ])

SimpleCov.start do
  minimum_coverage 100
  refuse_coverage_drop
  add_filter '/spec/'
end
