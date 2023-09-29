# frozen_string_literal: true

require_relative 'lib/rhykane/version'

Gem::Specification.new do |spec|
  spec.name = 'rhykane'
  spec.version = Rhykane::VERSION
  spec.authors = ['developers@sesac.com']
  spec.email = []

  spec.summary = 'Tool for mapping/normalizing data'
  spec.description = 'Tool for mapping/normalizing data, specifically row-based delimited datasets'
  spec.required_ruby_version = '>= 3.2.0'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) {
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  }
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'aws-sdk-s3', '~> 1.117'
  spec.add_dependency 'aws-sdk-ssm', '~> 1.146'
  spec.add_dependency 'dry-transformer', '~> 1.0'
  spec.add_dependency 'dry-validation', '~> 1.10'
  spec.add_dependency 'oj', '~> 3.13'
  spec.add_dependency 'rubyzip', '~> 2.3'

  spec.add_development_dependency 'climate_control'
  spec.add_development_dependency 'dotenv'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'faker'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rake'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov'
end
