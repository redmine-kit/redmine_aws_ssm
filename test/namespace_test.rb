# frozen_string_literal: true

require_relative 'test_helper'
require 'fileutils'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# The boot file defines RedmineAws::SSM before Redmine's code loader
# (Zeitwerk) sets up, so the loader names the files of the other Redmine AWS
# plugins under lib/redmine_aws/ at once, with the names that redmine_aws
# adds (costexplorer.rb is RedmineAws::CostExplorer). Checked in a Rails
# application whose loader is set up as Redmine's (test/namespace_app.rb),
# with a plugin whose files are named as theirs.
class NamespaceTest < Minitest::Test
  FILES = {
    'lib/redmine_aws/costexplorer.rb' => "module RedmineAws\n  module CostExplorer\n  end\nend\n",
    'lib/redmine_aws/ses.rb' => "module RedmineAws\n  module SES\n  end\nend\n",
    'lib/redmine_aws/ses/receiver.rb' => "module RedmineAws\n  module SES\n    class Receiver\n    end\n  end\nend\n"
  }.freeze

  def setup
    @root = Dir.mktmpdir
    FILES.each do |path, code|
      FileUtils.mkdir_p(File.dirname(File.join(@root, path)))
      File.write(File.join(@root, path), code)
    end
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_the_loader_names_the_plugins_files_after_the_boot_file
    result = run_namespace_app

    assert_equal %w[RedmineAws::Admin RedmineAws::CostExplorer RedmineAws::SES RedmineAws::SES::Receiver],
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
