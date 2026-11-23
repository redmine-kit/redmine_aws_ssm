# frozen_string_literal: true

require 'yaml'

# The plugin is also a gem, so that Bundler loads it before Rails reads the
# configuration (boot/redmine_kit_aws_ssm.rb). It is published to GitHub
# Packages (.github/workflows/gem.yml) with the plugin's run-time files, and
# the installed gem is linked into Redmine's plugins/ (docs/setup.md).
Gem::Specification.new do |spec|
  spec.name = 'redmine_kit_aws_ssm'
  spec.version = File.read(File.join(__dir__, 'boot/redmine_kit_aws_ssm/loader.rb'))[/VERSION = '([^']+)'/, 1]
  spec.summary = 'Loads environment variables from AWS Systems Manager Parameter Store'
  spec.authors = ['Redmine Kit']
  spec.license = 'GPL-2.0-or-later'
  spec.homepage = 'https://github.com/redmine-kit/redmine_aws_ssm'
  # The Ruby versions of Redmine 7.0 (its Gemfile: ruby '>= 3.2.0', '< 4.1.0').
  spec.required_ruby_version = ['>= 3.2', '< 4.1']
  # The tests are included: Serverless runs them inside its image.
  # config/locales: the plugin's name and description in Redmine's languages;
  # help: its pages for Redmine Kit Help.
  spec.files = Dir['{init.rb,LICENSE}', 'boot/**/*.rb', 'config/locales/*.yml', 'help/**/*', 'test/**/*.rb',
                   'config/dependencies.{rb,yml}']
  spec.require_paths = ['boot']
  spec.add_dependency 'aws-sdk-ssm', '~> 1.0'
  # Required by every Redmine Kit AWS plugin. Bundler.require does not load a
  spec.metadata['github_repo'] = 'ssh://github.com/redmine-kit/redmine_aws_ssm'
  # The plugins it requires (config/dependencies.yml): installing the gem installs them.
  YAML.safe_load_file(File.join(__dir__, 'config/dependencies.yml'))['requires'].each do |name, range|
    spec.add_dependency name, range
  end
  spec.metadata['rubygems_mfa_required'] = 'true'
end
