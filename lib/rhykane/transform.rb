# frozen_string_literal: true

require_relative 'config'
require_relative 'reader'
require_relative 'writer'
require_relative 'transformer'

class Rhykane
  class Transform
    class << self
      def call(input, output, **cfg)
        new(input, output, **cfg).()
      end
    end

    def initialize(input, output, transforms:, source:, destination:)
      rd           = Reader.(input, **source)
      @transformer = Transformer.(rd, **transforms)
      @writer      = Writer.(output, **destination)
    end

    def call
      transformer.each do |row|
        writer.puts(row)
      end
      writer.close
    end

    private

    attr_reader :transformer, :writer
  end
end
