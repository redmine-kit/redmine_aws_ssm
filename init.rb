# frozen_string_literal: true

# The plugins this one requires (config/dependencies.yml): without one,
# Redmine stops here and names it.
load File.expand_path('config/dependencies.rb', __dir__)

# The loading itself happens earlier, in boot/redmine_kit_aws_ssm.rb, without
# redmine_kit_aws, which Redmine loads later. The plugin still requires
# redmine_kit_aws, as every Redmine Kit AWS plugin does.
# The boot file comes from the plugin's line in Redmine's Gemfile.local,
# which Bundler loads; without it, Parameter Store would not be read, so
# Redmine stops here and names the line.
unless defined?(RedmineKit::Aws::Ssm::VERSION)
  raise Redmine::PluginRequirementError,
        "redmine_kit_aws_ssm plugin requires the line gem 'redmine_kit_aws_ssm' in Redmine's Gemfile.local " \
        '(docs/setup.md#installation)'
end

Redmine::Plugin.register :redmine_kit_aws_ssm do
  name 'Redmine Kit AWS SSM'
  author 'Redmine Kit'
  description 'Loads environment variables from AWS Systems Manager Parameter Store'
  version RedmineKit::Aws::Ssm::VERSION
  url 'https://github.com/redmine-kit/redmine_aws_ssm'
  author_url 'https://github.com/redmine-kit'
  requires_redmine version_or_higher: '7.0.0'
end
