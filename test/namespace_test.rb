# frozen_string_literal: true

require_relative 'test_helper'
require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# The boot file defines RedmineKitAws::SSM before Redmine's code loader
# (Zeitwerk) sets up, so the loader names the files of the other Redmine Kit AWS
# plugins under lib/redmine_kit_aws/ at once, with the names that redmine_kit_aws
# adds (costexplorer.rb is RedmineKitAws::CostExplorer). Checked in a Rails
# application whose loader is set up as Redmine's (test/namespace_app.rb),
# with a plugin whose files are named as theirs (test/fixtures/redmine_kit_aws_names).
class NamespaceTest < Minitest::Test
  # A plugin whose files are named as the other plugins' (lib/redmine_kit_aws/).
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

    assert_equal %w[RedmineKitAws::Admin RedmineKitAws::CostExplorer RedmineKitAws::SES RedmineKitAws::SES::Receiver],
                 result['names']
    assert_match(/\A\d+\.\d+\.\d+\z/, result['version'])
    assert_empty result['loaded']
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
