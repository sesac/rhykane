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
  end
end
