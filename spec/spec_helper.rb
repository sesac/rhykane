# frozen_string_literal: true

ENV['INSTRUMENT_APP'] = 'false'

require 'dotenv/load'
require 'pry'
require 'factory_bot'
require_relative 'support/simple_cov'
require_relative 'support/spec_helpers'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.expect_with :rspec do |c|
    c.include_chain_clauses_in_custom_matcher_descriptions = true
    c.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = '.rspec_status'
end
