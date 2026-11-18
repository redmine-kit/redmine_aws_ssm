# frozen_string_literal: true

require_relative 'test_helper'
require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# The boot file defines RedmineKit::Aws::Ssm before Redmine's code loader
# (Zeitwerk) sets up; the files of redmine_kit_aws and of the other Redmine Kit
# AWS plugins under lib/redmine_kit/aws/ still load, with the loader's default
# names (costexplorer.rb is RedmineKit::Aws::Costexplorer). Checked in a Rails
# application whose loader is set up as Redmine's (test/namespace_app.rb), with
# a plugin whose files are named as theirs (test/fixtures/redmine_kit_aws_names).
class NamespaceTest < Minitest::Test
  # A plugin whose files are named as the other plugins' (lib/redmine_kit/aws/).
  FIXTURE = File.expand_path('fixtures/redmine_kit_aws_names', __dir__)

  # A copy, as the application's root: Rails may write into it.
  def setup
    @root = Dir.mktmpdir
    FileUtils.cp_r("#{FIXTURE}/.", @root)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_the_loader_names_the_plugins_files_after_the_boot_file
    result = run_namespace_app

    assert_equal %w[RedmineKit::Aws::Admin RedmineKit::Aws::Costexplorer RedmineKit::Aws::Ses
                    RedmineKit::Aws::Ses::Receiver], result['names']
    assert_match(/\A\d+\.\d+\.\d+\z/, result['version'])
    assert_empty result['loaded']
  end

  # RedmineKit is the namespace of every plugin of the organization; the code
  # loader makes it from their lib/redmine_kit/ directories. A plugin with
  # lib/redmine_kit.rb would own it.
  def test_no_plugin_file_defines_redmine_kit
    refute_path_exists File.expand_path('../lib/redmine_kit.rb', __dir__)
  end

  private

  # Runs test/namespace_app.rb in a process of its own, with boot/ on the load
  # path, and returns what it printed after NAMESPACE_RESULT.
  def run_namespace_app
    env = { 'NAMESPACE_TEST_ROOT' => @root, 'COVERAGE_COMMAND' => "namespace #{name}", 'REDMINE_SSM_PATH' => nil }
    out, err, status = Open3.capture3(env, RbConfig.ruby, '-I', File.expand_path('../boot', __dir__),
                                      File.expand_path('namespace_app.rb', __dir__))
    assert status.success?, err
    JSON.parse(out[/^NAMESPACE_RESULT (.*)$/, 1])
  end
end
