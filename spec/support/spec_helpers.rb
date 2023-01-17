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
        Pathname.glob(File.join(fixture_path, '**/*.json')).each do |file|
          response_name = file.sub(fixture_path, '').to_s.tr('/', '_').split(file.extname).join.to_sym
          let(response_name) {
            JSON.parse(file.expand_path.read)
          }
        end
      end
    end
  end

  module S3
    def stub_s3_resource(stub_responses: true)
      resource = Aws::S3::Resource.new(stub_responses:)
      client   = resource.client

      client.stub_responses(:upload_part, method(:upload_part).to_proc)

      resource
    end

    def s3_root
      @s3_root ||= Pathname('/tmp/s3')
    end

    def s3_path(*args)
      s3_root.join(*args)
    end

    def upload_part(context)
      params  = context.params
      body    = params[:body]
      content = body.read
      etag    = Digest::MD5.hexdigest(content)
      dest    = s3_path(*params.values_at(:bucket, :key)).tap { |d|
        d.dirname.mkpath
      }
      body.rewind
      dest.open('a+') do |f| f.write(content) end

      OpenStruct.new(etag:, copy_part_result: OpenStruct.new(etag:))
    end
  end
end

RSpec.configure do |config|
  config.include SpecHelpers::Env
  config.include SpecHelpers::Fixtures
  config.include SpecHelpers::S3
end
