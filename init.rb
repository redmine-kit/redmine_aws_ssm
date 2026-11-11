# frozen_string_literal: true

# The loading itself happens earlier, in boot/redmine_aws_ssm.rb, without
# redmine_aws, which Redmine loads later. The plugin still requires
# redmine_aws, as every Redmine AWS plugin does.
Redmine::Plugin.register :redmine_aws_ssm do
  name 'Redmine AWS SSM'
  author 'Redmine Kit'
  description 'Loads environment variables from AWS Systems Manager Parameter Store before Rails starts'
  version '0.1.0'
  url 'https://github.com/redmine-kit/redmine_aws_ssm'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
  requires_redmine_plugin :redmine_aws, version_or_higher: '0.1.0'
end
