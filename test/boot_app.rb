# frozen_string_literal: true

# A minimal Rails application, run by boot_test.rb in a process of its own.
# It prints, as JSON, what the class body and config/database.yml see, which
# shows whether the parameters were read before the configuration.
require_relative 'coverage'
require 'json'
require 'rails'
require 'redmine_serverless_ssm'

module BootTest
  class Application < Rails::Application
    config.root = ENV.fetch('BOOT_TEST_ROOT')
    # Like Redmine's config/additional_environment.rb, inside the class body.
    HOST_IN_CLASS_BODY = ENV.fetch('REDMINE_DB_HOST', nil)
  end
end

database = BootTest::Application.config.database_configuration.fetch('production')
result = {
  class_body: BootTest::Application::HOST_IN_CLASS_BODY,
  database_host: database['host'],
  database_password: database['password'],
  loaded: RedmineServerlessSsm.loaded
}
puts "BOOT_RESULT #{JSON.generate(result)}"
