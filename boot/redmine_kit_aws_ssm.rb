# frozen_string_literal: true

require 'redmine_kit_aws_ssm/loader'

# Before the application's configuration, when REDMINE_SSM_PATH is set.
# config/database.yml and SECRET_KEY_BASE are read after this.
if defined?(Rails::Railtie)
  module RedmineKit
    module Aws
      module Ssm
        class Railtie < ::Rails::Railtie
          config.before_configuration do
            path = ENV.fetch('REDMINE_SSM_PATH', '')
            Ssm.loaded = Loader.load(path) unless path.empty?
          end
        end
      end
    end
  end
end
