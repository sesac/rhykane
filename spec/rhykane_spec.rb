# frozen_string_literal: true

require './lib/rhykane'

describe Rhykane do
  describe '.call' do
    let(:config_path) { './spec/fixtures/rhykane.yml' }

    it 'reads and parses a tsv file from S3, transforms it, and writes it back to S3' do
      cfg         = Rhykane::Jobs.load(config_path)[:map_a]
      input       = tsv_data.open
      res         = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path   = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      expected    = CSV.read(tsv_data, converters: %i[float], **cfg.dig(:source, :opts)).map(&:to_s).join

      described_class.(res, **cfg)

      expect(dest_path.read).to eq(expected)
    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'reads and parses tsv files in a zipped archive from S3, transforms them, ' \
       'and writes a single file back to S3' do
      cfg        = Rhykane::Jobs.load(config_path)[:zipped]
      input      = zipped_data.open
      res        = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path  = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }

      described_class.(res, **cfg)

      expect(dest_path.read).to eq(zipped_expected.read)
    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'reads and parses a gzipped txt file from S3, transforms it, and writes it back to a txt file in S3' do
      cfg        = Rhykane::Jobs.load(config_path)[:map_c]
      input      = gzip_data.open
      dat        = Zlib::GzipReader.open(gzip_data, &:read)
      expected   = CSV.parse(dat, col_sep: "\t", headers: true, converters: %i[float]).to_csv(write_headers: false)
      res        = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path  = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }

      described_class.(res, **cfg)

      expect(dest_path.read).to eq(expected)
    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'reads a file from S3, renames it, and writes it back to a file in S3' do
      cfg        = Rhykane::Jobs.load(config_path)[:io]
      input      = tsv_data.open
      res        = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path  = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }

      described_class.(res, **cfg)

      expect(dest_path.read).to eq(tsv_data.read)
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
