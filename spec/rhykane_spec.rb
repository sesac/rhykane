# frozen_string_literal: true

require './lib/rhykane'

describe Rhykane do
  describe '.call' do
    it 'reads file from S3, transforms it, and writes it back to S3' do
      cfg         = Rhykane::Jobs.load('./spec/fixtures/rhykane.yml')[:map_a]
      input_path  = Pathname('./spec/fixtures/data.tsv')
      input       = input_path.open
      res         = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path   = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      expected    = CSV.read(input_path, converters: %i[float], **cfg.dig(:source, :opts)).map(&:to_s).join

      described_class.(res, **cfg)

      expect(dest_path.read).to eq expected

    ensure
      dest_path.delete if dest_path.exist?
    end
  end

  describe '.for' do
    it 'returns executable instance for named job in a config' do
      res = stub_s3_resource

      result = described_class.for(:map_a, 'spec/fixtures', res)

      expect(result).to be_a described_class
    end
  end
end
