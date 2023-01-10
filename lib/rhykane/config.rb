# frozen_string_literal: true

require 'delegate'
require 'ostruct'
require 'yaml'

require 'dry-validation'

module Rhykane
  class Config < DelegateClass(Hash)
    def self.load(path)
      new(YAML.load_file(path, symbolize_names: true, permitted_classes: [Symbol]))
    end
  end
end
