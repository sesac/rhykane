# frozen_string_literal: true

require 'csv'

require './lib/rhykane/config'
require './lib/rhykane/reader'

describe Rhykane::Reader do
  describe '.call' do
    it 'raises an exception if an unknown type is passed' do
      expect { described_class.(StringIO.new, type: :foo) }.to raise_error ArgumentError
    end

    context 'with csv' do
      it 'deserializes io according to configuration options' do
        cfg  = { opts: { col_sep: "\t", headers: true } }
        data = tsv_data.open

        result = described_class.(data, **cfg).to_a

        expect(result).to eq CSV.open(tsv_data, **cfg[:opts].merge(header_converters: :symbol)).to_a
      end

      it 'deserializes io with headers specified in opts' do
        cfg  = { type: :csv, opts: { col_sep: "\t", headers: %w[id desc total] } }
        data = tsv_data_no_headers.open

        result = described_class.(data, **cfg).to_a

        expect(result).to eq CSV.open(tsv_data_no_headers, **cfg[:opts].merge(header_converters: :symbol)).to_a
      end

      it 'deserializes io according to configuration' do
        cfg_path = './spec/fixtures/rhykane.yml'
        cfg      = Rhykane::Jobs.load(cfg_path).dig(:map_a, :source)
        data     = tsv_data.open

        result = described_class.(data, **cfg).to_a

        expect(result).to eq CSV.open(tsv_data, **cfg[:opts].merge(header_converters: :symbol)).to_a
      end
    end

    context 'with json' do
      it 'deserializes io' do
        cfg      = { type: :json, opts: {} }
        expected = CSV.table(tsv_data, col_sep: "\t").map(&:to_h)
        io       = StringIO.new
        io.puts(expected.map { |row| JSON.generate(row) })
        io.rewind

        result = described_class.(io, **cfg).to_a

        expect(result).to eq expected
      end
    end
  end
end
