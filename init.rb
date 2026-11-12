# frozen_string_literal: true

# The loading itself happens earlier, in boot/redmine_aws_ssm.rb, without
# redmine_aws, which Redmine loads later. The plugin still requires
# redmine_aws, as every Redmine AWS plugin does.
# The version is RedmineAws::SSM::VERSION, which the boot file defines when
# Bundler loads it; a checkout without the Gemfile.local line loads it here.
require File.expand_path('boot/redmine_aws_ssm/loader', __dir__) unless defined?(RedmineAws::SSM::VERSION)

Redmine::Plugin.register :redmine_aws_ssm do
  # First, so that without redmine_aws Redmine stops with its own message
  # ("... requires the redmine_aws plugin") before anything else runs.
  requires_redmine_plugin :redmine_aws, version_or_higher: '0.1.0'
  name 'Redmine AWS SSM'
  author 'Redmine Kit'
  description 'Loads environment variables from AWS Systems Manager Parameter Store before Rails starts'
  version RedmineAws::SSM::VERSION
  url 'https://github.com/redmine-kit/redmine_aws_ssm'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end
