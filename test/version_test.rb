# frozen_string_literal: true

require_relative 'test_helper'

# The version is in one place, RedmineKitAws::SSM::VERSION, which the gemspec
# and init.rb read.
class VersionTest < Minitest::Test
  def test_the_gemspec_has_the_version_of_the_code
    spec = Gem::Specification.load(File.expand_path('../redmine_kit_aws_ssm.gemspec', __dir__))

    assert_equal RedmineKitAws::SSM::VERSION, spec.version.to_s
  end
end
