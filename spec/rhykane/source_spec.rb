# frozen_string_literal: true

require 'csv'

require './lib/rhykane/config'
require './lib/rhykane/source'

describe Rhykane::Source do
  describe '.call' do
    context 'with csv' do
      it 'deserializes io according to configuration options' do
        cfg  = { opts: { col_sep: "\t", headers: true } }
        path = Pathname('./spec/fixtures/data.tsv')
        data = path.open

        result = described_class.(data, **cfg).to_a

        expect(result).to eq CSV.open(path, **cfg[:opts].merge(header_converters: :symbol)).to_a
      end

      it 'deserializes io with headers specified in opts' do
        cfg  = { type: :csv, opts: { col_sep: "\t", headers: %w[id desc total] } }
        path = Pathname('./spec/fixtures/data_no_headers.tsv')
        data = path.open

        result = described_class.(data, **cfg).to_a

        expect(result).to eq CSV.open(path, **cfg[:opts].merge(header_converters: :symbol)).to_a
      end

      it 'deserializes io according to configuration' do
        cfg_path = './spec/fixtures/config.yml'
        cfg      = Rhykane::Config.load(cfg_path).dig(:map_a, :source)
        path     = Pathname('./spec/fixtures/data.tsv')
        data     = path.open

        result = described_class.(data, **cfg).to_a

        expect(result).to eq CSV.open(path, **cfg[:opts].merge(header_converters: :symbol)).to_a
      end
    end

    # context 'with json' do
    #   # TODO: spec with json type
    # end
  end
end
