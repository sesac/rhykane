# frozen_string_literal: true

require 'csv'

require './lib/rhykane/jobs'
require './lib/rhykane/transformer'

describe Rhykane::Transformer do
  describe '.call' do
    it 'does transformation on rows and values given configuration. ' \
       'Keys are not automatically renamed. ' \
       'Values are not required to be transformed.' do
      cfg      = { row: { rename_keys: { id: :record_id } } }
      opts     = { col_sep: "\t", headers: true, header_converters: :symbol }
      data     = CSV.open(tsv_data, **opts)
      headers  = data.first.headers.sort
      data.rewind
      expected = data.to_a.map(&:to_h).map(&:values)
      data.rewind

      result = described_class.(data, **cfg).each.to_a

      expect(result.map(&:values).map(&:sort)).to eq expected.map(&:sort)
      expect(result.map(&:keys).flatten.uniq.sort).not_to eq headers
    end

    it 'does not require row transformation, by default will return array of csv rows' do
      cfg      = {}
      opts     = { col_sep: "\t", headers: true, header_converters: :symbol }
      data     = CSV.open(tsv_data, **opts)
      expected = data.to_a
      data.rewind

      result = described_class.(data, **cfg).each.to_a

      expect(result).to eq expected
    end

    it 'allows adding additional fields with default values' do
      cfg      = { row: { deep_merge: { foo: nil, bat: nil } } }
      opts     = { col_sep: "\t", headers: true, header_converters: :symbol }
      data     = CSV.open(tsv_data, **opts)
      expected = data.to_a.map { |r| r.to_h.merge(cfg.dig(:row, :deep_merge)) }
      data.rewind

      result = described_class.(data, **cfg).each.to_a

      expect(result).to eq expected
    end

    it 'allows nesting fields under another' do
      cfg      = { row: { nest: [:misc, %i[desc total]] } }
      opts     = { col_sep: "\t", headers: true, header_converters: :symbol }
      data     = CSV.open(tsv_data, **opts)
      expected = data.to_a.map { |r| r.to_h.tap { |h| h[:misc] = { desc: h.delete(:desc), total: h.delete(:total) } } }
      data.rewind

      result = described_class.(data, **cfg).each.to_a

      expect(result).to eq expected
    end

    it 'allows setting default value if original value is nil' do
      cfg      = { row: { set_default: { desc: 'default value', total: 999 } } }
      opts     = { col_sep: "\t", headers: true, header_converters: :symbol }
      data     = CSV.open(tsv_data_empty_cells, **opts)
      expected = data.to_a.map { |r| r.to_h.tap { |h| h.merge!(cfg.dig(:row, :set_default)) if h[:desc].nil? } }
      data.rewind

      result = described_class.(data, **cfg).each.to_a

      expect(result).to eq expected
    end

    it 'allows custom functions like to_json & parse_period to be run on values' do
      cfg  = { row: { nest: [:misc, %i[desc total]] },
               values: { period: { parse_period: { type: :start, date_format: '01%m%y' } }, misc: :as_json } }
      opts = { col_sep: "\t", headers: true, header_converters: :symbol }
      data = CSV.open(tsv_data_empty_cells, **opts)

      result = described_class.(data, **cfg).each.to_a

      result.each do |row|
        expect { JSON.parse(row[:misc]).fetch('desc') }.not_to raise_error
        expect { Date.parse(row[:period]) }.not_to raise_error
      end
    end

    it 'sets up transformation pipeline from config' do
      cfg_path   = './spec/fixtures/rhykane.yml'
      cfg        = Rhykane::Jobs.load(cfg_path)[:map_a]
      opts       = cfg.dig(:source, :opts).merge(header_converters: :symbol)
      input_path = tsv_data
      data       = CSV.open(input_path, **opts)
      expected   = CSV.read(input_path, converters: %i[float], **opts).map(&:to_h).map(&:values)

      result = described_class.(data, **cfg[:transforms]).each.to_a

      expect(result.map(&:values)).to eq expected
      expect(result.map(&:keys).flatten.uniq).to eq cfg.dig(:transforms, :row, :accept_keys)
    end
  end
end
