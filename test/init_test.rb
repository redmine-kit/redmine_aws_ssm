# frozen_string_literal: true

require_relative 'test_helper'
require 'ripper'

# init.rb asks Redmine for redmine_aws before anything else in the register
# block: without redmine_aws, Redmine then stops with its own message
# ("... requires the redmine_aws plugin") rather than a NameError from a
# line that uses redmine_aws's code.
class InitTest < Minitest::Test
  INIT = File.expand_path('../init.rb', __dir__)

  def test_requires_redmine_aws_first
    assert_equal 'requires_redmine_plugin', first_call_in_register_block
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
