# frozen_string_literal: true

require './lib/rhykane'

describe Rhykane do
  describe '.call' do
    let(:config_path) { './spec/fixtures/rhykane.yml' }

    it 'reads and parses a tsv file from S3, transforms it, and writes it back to S3' do
      cfg       = Rhykane::Jobs.load(config_path)[:map_a]
      input     = tsv_data.open
      res       = stub_s3_resource(stub_responses: { get_object: { body: input } })
      dest_path = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      expected  = CSV.read(tsv_data, converters: %i[float], **cfg.dig(:source, :opts)).map(&:to_s).join

      described_class.(res, **cfg)

      expect(dest_path.read).to eq(expected)
    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'handles exceptions raised by the caller, gracefully shutting down' do
      cfg       = Rhykane::Jobs.load(config_path)[:map_a]
      input     = tsv_data.open
      cli       = stub_s3_resource(stub_responses: { get_object: { body: input } })
      err       = Class.new(StandardError)
      dest_path = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      expected  = CSV.read(tsv_data, **cfg.dig(:source, :opts)).first
      result    = nil
      orig_roe  = Thread.report_on_exception
      Thread.report_on_exception = false

      expect {
        described_class.(cli, **cfg) do |row|
          result = row
          raise err, result.to_s
        end
      }.to raise_error err, expected.to_s

      expect(dest_path).not_to be_exist
    ensure
      Thread.report_on_exception = orig_roe || false
      dest_path.delete if dest_path.exist?
    end

    it 'handles exceptions raised by reading, gracefully shutting down' do
      cfg       = Rhykane::Jobs.load(config_path)[:map_a]
      chunks    = tsv_data.read.chars.each_slice(tsv_data.size.divmod(3).first).map(&:join)
      err       = Class.new(StandardError)
      err_msg   = 'Ack!'
      dest_path = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      cli       = stub_s3_resource(stub_responses: {
                                     get_object: ->(ctx) {
                                       chunks.each_with_index { |chunk, idx|
                                         raise err, err_msg unless idx < 1

                                         ctx[:response_target].(chunk)
                                         sleep 0.1
                                       }
                                     }
                                   })

      expect { described_class.(cli, **cfg) }.to raise_error err, err_msg

      expect(dest_path).not_to be_exist
    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'reads and parses tsv files in a zipped archive from S3, transforms them, ' \
       'and writes a single file back to S3' do
      cfg       = Rhykane::Jobs.load(config_path)[:zipped]
      dest_path = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      cli       = stub_s3_resource(stub_responses: {
                                     get_object: ->(ctx) {
                                       IO.copy_stream(zipped_data, ctx.metadata[:response_target])
                                       ctx.metadata[:response_target].rewind

                                       { etag: Digest::MD5.hexdigest(zipped_data.read) }
                                     }
                                   })

      described_class.(cli, **cfg)

      expect(dest_path.read).to eq(zipped_expected.read)
    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'reads and parses tsv files in a zipped archive (macOS), transforms them, ' \
       'and writes a single file back to S3' do
      cfg       = Rhykane::Jobs.load(config_path)[:zipped_mac_os]
      dest_path = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      cli       = stub_s3_resource(stub_responses: {
                                     get_object: ->(ctx) {
                                       IO.copy_stream(zipped_mac_os_data, ctx.metadata[:response_target])
                                       ctx.metadata[:response_target].rewind

                                       { etag: Digest::MD5.hexdigest(zipped_mac_os_data.read) }
                                     }
                                   })

      described_class.(cli, **cfg)

      expect(dest_path.read).to eq(zipped_mac_os_expected.read)
    ensure
      dest_path.delete if dest_path.exist?
    end

    it 'reads and parses a gzipped txt file from S3, transforms it, and writes it back to a txt file in S3' do
      cfg       = Rhykane::Jobs.load(config_path)[:map_c]
      dat       = Zlib::GzipReader.open(gzip_data, &:read)
      expected  = CSV.parse(dat, col_sep: "\t", headers: true, converters: %i[float]).to_csv(write_headers: false)
      dest_path = s3_path(*cfg[:destination].values_at(:bucket, :key)).tap { |p| p.delete if p.exist? }
      cli       = stub_s3_resource(stub_responses: {
                                     get_object: ->(ctx) {
                                       IO.copy_stream(gzip_data, ctx.metadata[:response_target])
                                       ctx.metadata[:response_target].rewind

                                       { etag: Digest::MD5.hexdigest(zipped_data.read) }
                                     }
                                   })

      described_class.(cli, **cfg)

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
