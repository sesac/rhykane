# frozen_string_literal: true

require 'delegate'
require 'yaml'

require_relative 'config'

class Rhykane
  class Jobs < DelegateClass(Hash)
    def self.load(path)
      jobs = YAML.load_file(path, symbolize_names: true, permitted_classes: [Symbol])

      new(jobs)
    end

    def initialize(jobs)
      jobs = jobs.transform_values { |cfg| Config.new.(cfg) }

      super
    end
  end
end
