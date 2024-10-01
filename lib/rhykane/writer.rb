# frozen_string_literal: true

require 'delegate'
require 'forwardable'
require 'csv'
require 'oj'

class Rhykane
  class Writer
    extend Forwardable

    def self.call(io, type: :csv, **cfg)
      const_get(type.to_s.upcase, false).new(io, **cfg)
    rescue NameError
      raise ArgumentError, "Unknown source type: #{type}"
    end

    def initialize(io, opts: {}, **)
      @io, @opts = io, opts
    end

    delegate %i[close] => :io

    private

    attr_reader :io, :opts

    class CSV < Writer
      def initialize(*, **)
        super
        @io = ::CSV.new(io, **opts)
      end

      def puts(*rows) = io.puts(*rows.map(&method(:row_to_csv).to_proc))

      private

      def row_to_csv(row)
        case row
        in **row
          ::CSV::Row.new(row.keys, row.values)
        in *row
          row
        end
      end
    end

    class IO < Writer
      def puts(*rows) = io.puts(*rows)
    end

    class JSON < Writer
      def initialize(*, **)
        super
        Oj.mimic_JSON
      end

      def puts(*rows) = io.puts(*rows.map { |row| ::JSON.generate(row) })
    end
  end
end
