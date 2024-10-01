# frozen_string_literal: true

require_relative 'transformer'

class Rhykane
  class Transform
    def self.call(...) = new(...).()

    def initialize(input, output, **, &)
      @transformer = Transformer.(input, **, &)
      @output      = output
    end

    def call
      transformer.each do |row|
        output.puts(row)
      end
      output.close
    end

    private

    attr_reader :transformer, :output
  end
end
