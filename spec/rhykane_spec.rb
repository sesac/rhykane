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

    it 'reads a zipped file from S3, transforms it, and writes it back to a zip file in S3' do
      cfg        = Rhykane::Jobs.load('./spec/fixtures/zipped/rhykane.yml')[:zipped]
      input_path = Pathname('./spec/fixtures/zipped/input.zip')
      input      = input_path.open
      res        = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path  = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }

      described_class.(res, **cfg)

      expected_path = Pathname('./spec/fixtures/zipped/expected.txt')
      expected      = expected_path.read

      expect(dest_path.read).to eq expected

    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'reads a gz file from S3, transforms it, and writes it back to a txt file in S3' do
      cfg        = Rhykane::Jobs.load('./spec/fixtures/rhykane.yml')[:map_c]
      input_path = Pathname('./spec/fixtures/zipped/sample.txt.gz')
      input      = input_path.open
      res        = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path  = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }

      described_class.(res, **cfg)

      decompressed_content = Zlib::GzipReader.open(input_path) do |gz_file|
        gz_file.read
      end

      csv_data = CSV.parse(decompressed_content, col_sep: "\t", converters: %i[float])

      expected_headers = ['Id', 'desc', 'total']

      first_row_values = csv_data.first

      is_header = first_row_values == expected_headers

      if is_header
        csv_data.shift
      end

      expected = csv_data.map { |row| row.join(',') }.join("\n") + "\n"

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
