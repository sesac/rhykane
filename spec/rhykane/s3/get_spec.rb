# frozen_string_literal: true

require './lib/rhykane/s3/get'

describe Rhykane::S3::Get do
  describe '.call' do
    it 'streams file in s3 to a pipe and yields the pipe' do
      bucket, key = 'foo', 'streamable.txt'
      result      = StringIO.new
      io          = StringIO.new(Array.new(1024) { 'a' * 1024 }.join("\n"))
      cli         = stub_s3_resource(stub_responses: { get_object: { body: io } })

      described_class.(cli, bucket:, key:) do |rd| IO.copy_stream(rd, result) end

      expect(result.string).to eq io.string
    end

    it 'handles exceptions raised by the caller, gracefully shutting down' do
      bucket, key                = 'foo', 'streamable.txt'
      err                        = Class.new(StandardError)
      result                     = StringIO.new
      io                         = StringIO.new(Array.new(1024) { 'a' * 1024 }.join("\n"))
      cli                        = stub_s3_resource(stub_responses: { get_object: { body: io } })
      orig_roe                   = Thread.report_on_exception
      Thread.report_on_exception = false

      expect {
        described_class.(cli, bucket:, key:) do |rd|
          result << rd.readline
          raise err, result.string
        end
      }.to raise_error err, io.tap(&:rewind).string.lines.first
    ensure
      Thread.report_on_exception = orig_roe || false
    end

    it 'handles exceptions raised by reading, gracefully shutting down' do
      bucket, key = 'foo', 'streamable.txt'
      result      = StringIO.new
      data        = Array.new(1024) { 'a' * 1024 }.join("\n")
      chunks      = data.chars.each_slice(data.size.divmod(3).first).map(&:join)
      err         = Class.new(StandardError)
      err_msg     = 'Ack!'
      cli         = stub_s3_resource(stub_responses: {
                                       get_object: ->(ctx) {
                                         chunks.each_with_index { |chunk, idx|
                                           raise err, err_msg unless idx < 1

                                           ctx[:response_target].(chunk)
                                           sleep 0.1
                                         }
                                       }
                                     })

      expect {
        described_class.(cli, bucket:, key:) do |rd| IO.copy_stream(rd, result) end
      }.to raise_error err, err_msg

      expect(result.string).to eq(chunks.first)
    end

    it 'streams zip file in s3 to a pipe and yields the pipe' do
      bucket, key = 'foo', 'streamable.txt.zip'
      result      = StringIO.new
      cli         = stub_s3_resource(stub_responses: {
                                       get_object: ->(ctx) {
                                         IO.copy_stream(zipped_data, ctx.metadata[:response_target])
                                         ctx.metadata[:response_target].rewind

                                         { etag: Digest::MD5.hexdigest(zipped_data.read) }
                                       }
                                     })

      described_class.(cli, bucket:, key:) do |rd|
        IO.copy_stream(rd, result)
      end

      expect(result.string.lines.size).to eq(zipped_expected.read.lines.size + 1)
    end

    it 'streams password-protected zip file in s3 to a pipe and yields the pipe' do
      bucket, key = 'foo', 'streamable.txt.zip'
      result      = StringIO.new
      cli         = stub_s3_resource(stub_responses: {
                                       get_object: ->(ctx) {
                                         IO.copy_stream(zipped_password_data, ctx.metadata[:response_target])
                                         ctx.metadata[:response_target].rewind

                                         { etag: Digest::MD5.hexdigest(zipped_data.read) }
                                       }
                                     })

      described_class.(cli, bucket:, key:, password: 'foo') do |rd|
        IO.copy_stream(rd, result)
      end

      expect(result.string.lines.size).to eq(zipped_expected.read.lines.size + 1)
    end

    it 'streams a macOS zip file in s3 to a pipe and yields the pipe' do
      bucket, key = 'foo', 'streamable.txt.zip'
      result      = StringIO.new
      cli         = stub_s3_resource(stub_responses: {
                                       get_object: ->(ctx) {
                                         IO.copy_stream(zipped_mac_os_data, ctx.metadata[:response_target])
                                         ctx.metadata[:response_target].rewind

                                         { etag: Digest::MD5.hexdigest(zipped_data.read) }
                                       }
                                     })

      described_class.(cli, bucket:, key:) do |rd|
        IO.copy_stream(rd, result)
      end

      expect(result.string.lines.size).to eq(zipped_mac_os_expected.readlines.size)
    end
  end
end
