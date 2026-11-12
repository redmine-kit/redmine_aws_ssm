# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'
require 'rbconfig'
require 'ripper'

# init.rb asks Redmine for redmine_aws before anything else in the register
# block: without redmine_aws, Redmine then stops with its own message
# ("... requires the redmine_aws plugin") rather than a NameError from a
# line that uses redmine_aws's code.
class InitTest < Minitest::Test
  INIT = File.expand_path('../init.rb', __dir__)

  # A script that loads init.rb with a stub of Redmine::Plugin and without
  # the plugin's code, and prints the message of Redmine's requirement error.
  STUB = <<~RUBY.freeze
    module Redmine
      class PluginRequirementError < StandardError; end

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

  def test_requires_redmine_aws_first
    assert_equal 'requires_redmine_plugin', first_call_in_register_block
  end

  # Without the plugin's line in Gemfile.local, Bundler does not load the
  # plugin's code, and Redmine stops with an error that names the line.
  def test_without_the_gemfile_local_line_redmine_stops_and_names_it
    out, status = Open3.capture2e(RbConfig.ruby, '-e', STUB)

    assert status.success?, out
    assert_includes out, "gem 'redmine_aws_ssm' in Redmine's Gemfile.local"
  end

  private

  # The first method called in the block of Redmine::Plugin.register.
  def first_call_in_register_block
    tokens = Ripper.lex(File.read(INIT)).map { |(_, type, token)| [type, token] }
    register = tokens.index([:on_ident, 'register'])
    start = ((register + 1)...tokens.size).find { |i| tokens[i] == [:on_kw, 'do'] }
    tokens[start..].find { |type, _| type == :on_ident }&.last
  end
end
