# frozen_string_literal: true

require './lib/rhykane/s3/put'

describe Rhykane::S3::Put do
  describe '.call' do
    it 'streams file in s3 to a pipe and yields the pipe' do
      res      = stub_s3_resource
      key_path = s3_path(bucket = 'foo', key = 'streamable.txt').tap { |p| p.delete if p.exist? }
      io       = StringIO.new.tap { |s|
        s.puts(*Array.new(1024) { 'a' * 1024 })
        s.rewind
      }

      described_class.(res, io, bucket:, key:)

      expect(key_path.read).to eq io.tap(&:rewind).read
    end
  end
end
