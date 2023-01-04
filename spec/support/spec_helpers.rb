# frozen_string_literal: true

require 'climate_control'

module SpecHelpers
  module Env
    def with_modified_env(options, &block)
      ClimateControl.modify(options, &block)
    end
  end

  module Fixtures
    def self.included(mod)
      mod.instance_eval do
        fixture_path = './spec/fixtures/'
        Pathname.glob(File.join(fixture_path, '**/*.json')).each do |file|
          response_name = file.sub(fixture_path, '').to_s.tr('/', '_').split(file.extname).join.to_sym
          let(response_name) {
            JSON.parse(file.expand_path.read)
          }
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.include SpecHelpers::Env
  config.include SpecHelpers::Fixtures
end
