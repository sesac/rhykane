# frozen_string_literal: true

require 'delegate'
require 'csv'
require 'oj'

module Rhykane
  class Writer
    def self.call(io, type: :csv, **cfg)
      const_get(type.to_s.upcase, false).new(io, **cfg)
    rescue NameError
      raise ArgumentError, "Unknown source type: #{type}"
    end

    def initialize(io, opts: {}, **)
      @io   = io
      @opts = opts
    end

    private

    attr_reader :io, :opts

    class CSV < Writer
      def initialize(*, **)
        super
        @io = ::CSV.new(io, **opts)
      end

      def puts(*rows)
        io.puts(*rows.map { |row| ::CSV::Row.new(row.keys, row.values) })
      end
    end

    class JSON < Writer
      def initialize(*, **)
        super
        Oj.mimic_JSON
      end

      def puts(*rows)
        io.puts(*rows.map { |row| ::JSON.generate(row) })
      end
    end
  end
end
