# frozen_string_literal: true

# The loading itself happens earlier, in boot/redmine_aws_ssm.rb.
Redmine::Plugin.register :redmine_aws_ssm do
  name 'Redmine AWS SSM'
  author 'Redmine Kit'
  description 'Loads environment variables from AWS Systems Manager Parameter Store before Rails starts'
  version '0.1.0'
  url 'https://github.com/redmine-kit/redmine_aws_ssm'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end
