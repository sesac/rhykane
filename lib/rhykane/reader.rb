# frozen_string_literal: true

require 'delegate'
require 'csv'
require 'oj'

class Rhykane
  class Reader
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

    class CSV < DelegateClass(::CSV)
      def initialize(io, opts: {}, **)
        opts = { header_converters: :symbol }.merge(opts)
        super(::CSV.new(io, **opts))
      end
    end

    class JSON < Reader
      include Enumerable

      def initialize(*, **)
        super
        Oj.mimic_JSON
        @opts = { symbolize_names: true }.merge(opts)
      end

      def each
        return enum_for(__method__) unless block_given?

        io.each do |row| yield ::JSON.parse(row, **opts) end
      end
    end
  end
end
