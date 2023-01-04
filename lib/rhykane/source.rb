# frozen_string_literal: true

module Rhykane
  class Source
    def self.call(io, **cfg)
      new(**cfg).(io)
    end

    def initialize(type: :csv, opts: {}, **)
      @type = type
      @opts = opts
    end

    def call(io)
      CSV.new(io, **opts.merge(header_converters: :symbol))
    end

    private

    attr_reader :type, :opts
  end
end
