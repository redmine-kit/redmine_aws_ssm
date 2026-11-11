# frozen_string_literal: true

# A minimal Rails application, run by namespace_test.rb in a process of its
# own. Its code loader is set up as Redmine 7.0 sets up its own: the
# plugins' lib/ are root directories (Redmine::PluginLoader), and the
# loaders get a new inflector in an initializer
# (config/initializers/zeitwerk.rb). The plugin's boot file is loaded first,
# as Bundler loads it, so RedmineAws is defined before the loader sets up.
# It prints, as JSON, what the files under lib/redmine_aws define.
require_relative 'coverage'
require 'json'
require 'logger'
require 'rails'
require 'redmine_aws_ssm'

module NamespaceApp
  REDMINE_AWS = Gem.loaded_specs.fetch('redmine_aws').full_gem_path
  ROOT = ENV.fetch('NAMESPACE_TEST_ROOT')

  class Application < Rails::Application
    config.root = ROOT
    config.eager_load = false
    config.logger = Logger.new(nil)

    initializer 'namespace_app.loaders' do
      [File.join(REDMINE_AWS, 'lib'), File.join(ROOT, 'lib')].each { |dir| Rails.autoloaders.main.push_dir(dir) }
      Rails.autoloaders.each { |loader| loader.inflector = Zeitwerk::Inflector.new }
    end
  end
end

NamespaceApp::Application.initialize!
# What redmine_aws's init.rb does: the loader skips lib/redmine_aws.rb,
# because RedmineAws is defined already.
require File.join(NamespaceApp::REDMINE_AWS, 'lib/redmine_aws') unless defined?(RedmineAws::VERSION)
# What bin/rails zeitwerk:check does.
Zeitwerk::Loader.eager_load_all

result = {
  version: RedmineAws::VERSION,
  names: [RedmineAws::Admin, RedmineAws::CostExplorer, RedmineAws::SES, RedmineAws::SES::Receiver].map(&:name),
  loaded: RedmineAws::SSM.loaded
}
puts "NAMESPACE_RESULT #{JSON.generate(result)}"
