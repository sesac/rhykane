# frozen_string_literal: true

require './lib/rhykane/config'

describe Rhykane::Config do
  describe '#call' do
    it 'raises an error if a job config is invalid' do
      cfg = {}

      expect { described_class.new.(cfg) }.to raise_error described_class::ConfigurationError
    end

    it 'returns a validated configuration hash' do
      cfg = { transforms: {},
              source: { bucket: 'foo', key: 'bar', type: 'baz' },
              destination: { bucket: 'foo', key: 'bar', type: 'baz' } }

      result = described_class.new.(cfg)

      expect(result).to eq cfg
    end
  end
end
