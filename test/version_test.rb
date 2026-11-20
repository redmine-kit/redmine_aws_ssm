# frozen_string_literal: true

require_relative 'test_helper'

# The version is in one place, RedmineKit::Aws::Ssm::VERSION, which the gemspec
# and init.rb read.
class VersionTest < Minitest::Test
  def test_the_gemspec_has_the_version_of_the_code
    spec = Gem::Specification.load(File.expand_path('../redmine_kit_aws_ssm.gemspec', __dir__))

    assert_equal RedmineKit::Aws::Ssm::VERSION, spec.version.to_s
  end

  # The locale files hold the plugin's name and description (Administration ›
  # Plugins): the gem, which is linked into plugins/, carries them.
  def test_the_gem_has_the_locale_files
    spec = Gem::Specification.load(File.expand_path('../redmine_kit_aws_ssm.gemspec', __dir__))

    assert_empty %w[config/locales/en.yml config/locales/ja.yml] - spec.files
  end
end
