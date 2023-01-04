# frozen_string_literal: true

require './lib/rhykane/config'

describe Rhykane::Config do
  describe '.load' do
    it 'loads configuration from a yml file' do
      path = './spec/fixtures/config.yml'

      result = described_class.load(path)

      expect(result).to eq YAML.load_file(path, symbolize_names: true)
    end
  end
end
