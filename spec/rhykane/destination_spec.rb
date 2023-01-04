# frozen_string_literal: true

require 'csv'

require './lib/rhykane/config'
require './lib/rhykane/destination'

describe Rhykane::Destination do
  describe '.call' do
    context 'with csv' do
      it 'serializes io according to configuration options' do
        cfg  = { type: :csv, opts: { write_headers: false } }
        path = Pathname('./spec/fixtures/data.tsv')
        src  = CSV.read(path, col_sep: "\t", headers: true, header_converters: :symbol)
        io   = StringIO.new
        dest = described_class.(io, **cfg)

        src.each do |row| dest.puts(row) end

        expect(io.string.split("\n")).to eq src.to_s.split("\n")[1..]
      end

      it 'serializes io with headers specified in opts' do
        headers = %w[id title total]
        cfg     = { type: :csv, opts: { col_sep: "\t", headers:, write_headers: true } }
        path    = Pathname('./spec/fixtures/data.tsv')
        src     = CSV.read(path, col_sep: "\t", headers: true, header_converters: :symbol)
        io      = StringIO.new
        dest    = described_class.(io, **cfg)

        src.each do |row| dest.puts(row) end
        dest.rewind

        expect(dest.first.to_h.values).to eq headers
        expect(dest.to_a.map(&:to_s)).to eq src.each.to_a.map(&:to_s)
      end

      it 'serializes io according to configuration' do
        cfg_path = './spec/fixtures/config.yml'
        cfg      = Rhykane::Config.load(cfg_path).dig(:map_a, :destination)
        path     = Pathname('./spec/fixtures/data.tsv')
        src  = CSV.read(path, col_sep: "\t", headers: true, header_converters: :symbol)
        io   = StringIO.new
        dest = described_class.(io, **cfg)

        src.each do |row| dest.puts(row) end

        expect(io.string.split("\n")).to eq src.to_s.split("\n")[1..]
      end
    end

    context 'with json' do
      # TODO: spec with json type
    end
  end
end
