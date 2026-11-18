# frozen_string_literal: true

# Coverage of boot/ with SimpleCov when PLUGIN_COVERAGE is set (bin/test), in
# Cobertura for Codecov and in HTML, in coverage/. The boot test's processes
# load this too: they only store their results, which the test process merges
# into the reports when it ends.
if ENV['PLUGIN_COVERAGE'] && !(defined?(SimpleCov) && SimpleCov.running)
  require 'simplecov'
  require 'simplecov-cobertura'

  module SSMTestCoverage
    # Writes nothing; the result is still stored for merging.
    class StoreOnly
      def format(_result) = nil
    end
  end

  child = ENV.key?('COVERAGE_COMMAND')
  SimpleCov.start do
    root File.expand_path('..', __dir__)
    coverage_dir 'coverage'
    command_name ENV.fetch('COVERAGE_COMMAND', 'tests')
    # Every file of the plugin, so that a file no test loads shows as 0%
    # (init.rb, which only Redmine loads). The glob is absolute, not read from
    # the current directory.
    track_files "#{root}/{init.rb,boot/**/*.rb}"
    add_filter '/test/'
    formatters(child ? [SSMTestCoverage::StoreOnly] : [SimpleCov::Formatter::CoberturaFormatter,
                                                       SimpleCov::Formatter::HTMLFormatter])
  end
  SimpleCov.print_error_status = false if child
end
