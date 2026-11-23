# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'
require 'rbconfig'

# init.rb checks the plugins it requires first (config/dependencies.rb):
# without redmine_kit_aws, Redmine stops and names it, before a line that
# uses redmine_kit_aws's code could raise a NameError.
class InitTest < Minitest::Test
  INIT = File.expand_path('../init.rb', __dir__)

  # A script that loads init.rb with a stub of Redmine::Plugin and of its list
  # of plugin folders (FOLDERS), without the plugin's code, and prints the
  # message of Redmine's requirement error.
  STUB = <<~RUBY.freeze
    module Redmine
      class PluginRequirementError < StandardError; end
      PluginPath = Struct.new(:to_s)
      module PluginLoader
        def self.directories = ENV.fetch('FOLDERS').split.map { |name| PluginPath.new("/redmine/plugins/\#{name}") }
      end

      class Plugin
        def self.register(*) = raise('registered')
      end
    end
    begin
      load #{INIT.inspect}
    rescue Redmine::PluginRequirementError => e
      print e.message
    end
  RUBY

  def test_without_redmine_kit_aws_redmine_stops_and_names_it
    out, status = Open3.capture2e({ 'FOLDERS' => 'redmine_kit_aws_x' }, RbConfig.ruby, '-e', STUB)

    assert status.success?, out
    assert_includes out, 'requires the plugin redmine_kit_aws:'
  end

  # Without the plugin's line in Gemfile.local, Bundler does not load the
  # plugin's code, and Redmine stops with an error that names the line.
  def test_without_the_gemfile_local_line_redmine_stops_and_names_it
    out, status = Open3.capture2e({ 'FOLDERS' => 'redmine_kit_aws' }, RbConfig.ruby, '-e', STUB)

    assert status.success?, out
    assert_includes out, "gem 'redmine_kit_aws_ssm' in Redmine's Gemfile.local"
  end
end
