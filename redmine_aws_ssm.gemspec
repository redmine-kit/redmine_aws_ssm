# frozen_string_literal: true

# The plugin is also a gem, so that Bundler loads it before Rails reads the
# configuration (boot/redmine_aws_ssm.rb). It is published to GitHub
# Packages (.github/workflows/gem.yml) with the plugin's run-time files, and
# the installed gem is linked into Redmine's plugins/ (docs/setup.md).
Gem::Specification.new do |spec|
  spec.name = 'redmine_aws_ssm'
  spec.version = File.read(File.join(__dir__, 'boot/redmine_aws_ssm/loader.rb'))[/VERSION = '([^']+)'/, 1]
  spec.summary = 'Loads environment variables from AWS Systems Manager Parameter Store before Rails starts'
  spec.authors = ['Redmine Kit']
  spec.license = 'GPL-2.0-or-later'
  spec.homepage = 'https://github.com/redmine-kit/redmine_aws_ssm'
  # The Ruby versions of Redmine 7.0 (its Gemfile: ruby '>= 3.2.0', '< 4.1.0').
  spec.required_ruby_version = '>= 3.2'
  # The tests are included: Serverless runs them inside its image.
  spec.files = Dir['{init.rb,LICENSE}', 'boot/**/*.rb', 'test/**/*.rb']
  spec.require_paths = ['boot']
  spec.add_dependency 'aws-sdk-ssm', '~> 1.0'
  # Required by every Redmine AWS plugin. Bundler.require does not load a
  # dependency, so boot/ runs without it.
  spec.add_dependency 'redmine_aws', '~> 0.1'
  spec.metadata['github_repo'] = 'ssh://github.com/redmine-kit/redmine_aws_ssm'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
