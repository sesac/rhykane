# frozen_string_literal: true

require './lib/rhykane/s3/get'

describe Rhykane::S3::Get do
  describe '.call' do
    it 'streams file in s3 to a pipe and yields the pipe' do
      bucket, key = 'foo', 'streamable.txt'
      result      = StringIO.new
      io          = StringIO.new.tap { |s|
        s.puts(*Array.new(1024) { 'a' * 1024 })
        s.rewind
      }
      res = stub_s3_resource(stub_responses: { get_object: { body: io } })

      described_class.(res, bucket:, key:) do |rd|
        IO.copy_stream(rd, result)
      end

      expect(result.string).to eq io.string
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
  end
end
