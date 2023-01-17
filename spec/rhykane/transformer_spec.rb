# frozen_string_literal: true

require 'csv'

require './lib/rhykane/config'
require './lib/rhykane/transformer'

describe Rhykane::Transformer do
  describe '.call' do
    it 'does transformation on rows and values given configuration. ' \
       'Keys are not automatically renamed. ' \
       'Values are not required to be transformed.' do
      cfg      = { row: { rename_keys: { id: :record_id } } }
      opts     = { col_sep: "\t", headers: true, header_converters: :symbol }
      data     = CSV.open(Pathname('./spec/fixtures/data.tsv'), **opts)
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
      data     = CSV.open(Pathname('./spec/fixtures/data.tsv'), **opts)
      expected = data.to_a
      data.rewind

      result = described_class.(data, **cfg).each.to_a

      expect(result).to eq expected
    end

    it 'sets up transformation pipeline from config' do
      cfg_path   = './spec/fixtures/rhykane.yml'
      cfg        = Rhykane::Jobs.load(cfg_path)[:map_a]
      opts       = cfg.dig(:source, :opts).merge(header_converters: :symbol)
      input_path = Pathname('./spec/fixtures/data.tsv')
      data       = CSV.open(input_path, **opts)
      expected   = CSV.read(input_path, converters: %i[float], **opts).map(&:to_h).map(&:values)

      result = described_class.(data, **cfg[:transforms]).each.to_a

      expect(result.map(&:values)).to eq expected
      expect(result.map(&:keys).flatten.uniq).to eq cfg.dig(:transforms, :row, :accept_keys)
    end
  end
end
