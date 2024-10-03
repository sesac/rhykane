# frozen_string_literal: true

require 'climate_control'

module SpecHelpers
  module Env
    def with_modified_env(options, &)
      ClimateControl.modify(options, &)
    end
  end

  module Fixtures
    def self.included(mod)
      mod.instance_eval do
        fixture_path = './spec/fixtures/'
        Pathname.glob(File.join(fixture_path, '**/*.*')).each do |file|
          response_name = file.sub(fixture_path, '').to_s.tr('/', '_').split('.').first.to_sym
          let(response_name) { file }
        end
      end
    end
  end

  module S3
    def stub_s3_resource(stub_responses: true)
      Aws::S3::Resource.new(stub_responses:).tap { |this|
        this.client.stub_responses(:upload_part, method(:upload_part).to_proc)
      }
    end

    def s3_root               = @s3_root ||= Pathname('/tmp/s3')
    def s3_path(*)            = s3_root.join(*)
    def content_etag(content) = Digest::MD5.hexdigest(content)

    def upload_part(context)
      bucket, key, body = context.params.values_at(:bucket, :key, :body)
      content           = body.read.tap { body.rewind }
      etag              = content_etag(content)
      dest              = s3_path(bucket, key).tap { |this| this.dirname.mkpath}
      dest.open('a+') do |file| file.write(content) end

      OpenStruct.new(etag:, copy_part_result: OpenStruct.new(etag:))
    end
  end
end

RSpec.configure do |config|
  config.include SpecHelpers::Env
  config.include SpecHelpers::Fixtures
  config.include SpecHelpers::S3
end
