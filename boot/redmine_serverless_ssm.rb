# frozen_string_literal: true

require 'redmine_serverless_ssm/loader'

# Before the application's configuration, when REDMINE_SSM_PATH is set.
# config/database.yml and SECRET_KEY_BASE are read after this.
if defined?(Rails::Railtie)
  module RedmineServerlessSsm
    class Railtie < Rails::Railtie
      config.before_configuration do
        path = ENV.fetch('REDMINE_SSM_PATH', '')
        RedmineServerlessSsm.loaded = RedmineServerlessSsm::Loader.load(path) unless path.empty?
      end
    end
  end
end
