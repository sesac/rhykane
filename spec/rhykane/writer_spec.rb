# frozen_string_literal: true

require 'csv'

require './lib/rhykane/config'
require './lib/rhykane/writer'

describe Rhykane::Writer do
  describe '.call' do
    it 'raises an exception if an unknown type is passed' do
      expect { described_class.(StringIO.new, type: :foo) }.to raise_error ArgumentError
    end

    context 'with csv' do
      it 'serializes io according to configuration options' do
        cfg  = { type: :csv, opts: { write_headers: false } }
        path = Pathname('./spec/fixtures/data.tsv')
        src  = CSV.table(path, col_sep: "\t")
        io   = StringIO.new
        dest = described_class.(io, **cfg)

        src.each do |row| dest.puts(row.to_h) end

        expect(io.string.split("\n")).to eq src.to_s.split("\n")[1..]
      end

      it 'serializes io with headers specified in opts' do
        headers = %w[id title total]
        cfg     = { type: :csv, opts: { col_sep: "\t", headers:, write_headers: true } }
        path    = Pathname('./spec/fixtures/data.tsv')
        src     = CSV.table(path, col_sep: "\t")
        io      = StringIO.new
        dest    = described_class.(io, **cfg)

        src.each do |row| dest.puts(row.to_h) end
        io.rewind
        result = CSV.parse(io.string, col_sep: "\t", headers: true).to_s.lines

        expect(result.first.strip).to eq headers.join(',')
        expect(result[1..]).to eq src.to_s.lines[1..]
      end

      it 'serializes io according to configuration' do
        cfg_path = './spec/fixtures/rhykane.yml'
        cfg      = Rhykane::Jobs.load(cfg_path).dig(:map_a, :destination)
        path     = Pathname('./spec/fixtures/data.tsv')
        src      = CSV.table(path, col_sep: "\t")
        io       = StringIO.new
        dest     = described_class.(io, **cfg)

        src.each do |row| dest.puts(row.to_h) end

        expect(io.string.split("\n")).to eq src.to_s.split("\n")[1..]
      end
    end

    context 'with json' do
      Oj.mimic_JSON

      it 'serializes io' do
        cfg      = { type: :json, opts: {} }
        path     = Pathname('./spec/fixtures/data.tsv')
        src      = CSV.table(path, col_sep: "\t").map(&:to_h)
        expected = src.map { |row| JSON.generate(row) }
        io       = StringIO.new
        dest     = described_class.(io, **cfg)

        src.each do |row| dest.puts(row) end

        expect(io.string.split("\n")).to eq expected
      end
    end
  end
end
