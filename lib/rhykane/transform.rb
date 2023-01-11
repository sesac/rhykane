# frozen_string_literal: true

require_relative 'config'
require_relative 'reader'
require_relative 'writer'
require_relative 'transformer'


module Rhykane
  class Transform
    class << self
      def call(input, output, **cfg)
        new(input, output, **cfg).()
      end
    end

    def initialize(input, output, transforms:, reader:, writer:)
      rd           = Reader.(input, **reader)
      @transformer = Transformer.(rd, **transforms)
      @writer      = Writer.(output, **writer)
    end

    def call
      transformer.each do |row|
        writer.puts(row)
      end
    end

    private

    attr_reader :transformer, :writer
  end
end
