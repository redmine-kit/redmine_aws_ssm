# frozen_string_literal: true

# The plugin is also a gem, so that Bundler loads it before Rails reads the
# configuration (boot/redmine_serverless_ssm.rb). Redmine's Gemfile.local adds
# it by path (docs/README.md#installation).
Gem::Specification.new do |spec|
  spec.name = 'redmine_serverless_ssm'
  spec.version = '0.1.0'
  spec.summary = 'Loads environment variables from AWS Systems Manager Parameter Store before Rails starts'
  spec.authors = ['Redmine Kit']
  spec.license = 'GPL-2.0-or-later'
  spec.homepage = 'https://github.com/redmine-kit/redmine_serverless_ssm'
  spec.required_ruby_version = '>= 4.0'
  spec.files = Dir['boot/**/*.rb']
  spec.require_paths = ['boot']
  spec.add_dependency 'aws-sdk-ssm', '~> 1.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
