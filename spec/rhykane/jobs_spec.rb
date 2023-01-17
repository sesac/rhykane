# frozen_string_literal: true

require './lib/rhykane/jobs'

describe Rhykane::Jobs do
  describe '.load' do
    it 'loads jobs from a yml file' do
      path = './spec/fixtures/rhykane.yml'

      result = described_class.load(path)

      expect(result).to eq YAML.load_file(path, symbolize_names: true)
    end
  end

  describe '.new' do
    it 'raises an error if a job config is invalid' do
      cfg = { job: {} }

      expect { described_class.new(cfg) }.to raise_error Rhykane::Config::ConfigurationError
    end
  end
end
