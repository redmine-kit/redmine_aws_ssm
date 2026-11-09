# frozen_string_literal: true

require_relative 'test_helper'
require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# Starts a Rails application (test/boot_app.rb) with REDMINE_SSM_PATH and
# checks that the parameters are in ENV before the class body and
# config/database.yml are evaluated, as Redmine's are.
class BootTest < Minitest::Test
  DATABASE_YML = <<~YAML
    production:
      adapter: postgresql
      host: <%= ENV['REDMINE_DB_HOST'] %>
      password: <%= ENV['REDMINE_DB_PASSWORD'] %>
  YAML

  def setup
    @ssm = Aws::SSM::Client.new
    @path = "/boot-test-#{SecureRandom.hex(4)}/env/"
    @root = Dir.mktmpdir
    Dir.mkdir("#{@root}/config")
    File.write("#{@root}/config/database.yml", DATABASE_YML)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def boot(env)
    script = File.expand_path('boot_app.rb', __dir__)
    boot_dir = File.expand_path('../boot', __dir__)
    child_env = { 'BOOT_TEST_ROOT' => @root, 'COVERAGE_COMMAND' => "boot #{name}",
                  'REDMINE_DB_HOST' => nil, 'REDMINE_DB_PASSWORD' => nil }.merge(env)
    out, err, status = Open3.capture3(child_env, RbConfig.ruby, '-I', boot_dir, script)
    assert status.success?, err
    JSON.parse(out[/^BOOT_RESULT (.*)$/, 1])
  end

  def test_parameters_are_read_before_the_configuration
    @ssm.put_parameter(name: "#{@path}REDMINE_DB_HOST", value: 'db.example.internal', type: 'String')
    @ssm.put_parameter(name: "#{@path}REDMINE_DB_PASSWORD", value: 'from-ssm', type: 'SecureString')

    result = boot('REDMINE_SSM_PATH' => @path)

    assert_equal 'db.example.internal', result['class_body']
    assert_equal 'db.example.internal', result['database_host']
    assert_equal 'from-ssm', result['database_password']
    assert_equal %w[REDMINE_DB_HOST REDMINE_DB_PASSWORD], result['loaded'].sort
  end

  def test_nothing_is_read_without_the_path
    @ssm.put_parameter(name: "#{@path}REDMINE_DB_HOST", value: 'db.example.internal', type: 'String')

    result = boot({})

    assert_nil result['database_host']
    assert_empty result['loaded']
  end

  def test_start_up_fails_when_parameter_store_cannot_be_reached
    script = File.expand_path('boot_app.rb', __dir__)
    env = { 'BOOT_TEST_ROOT' => @root, 'REDMINE_SSM_PATH' => @path, 'AWS_ENDPOINT_URL' => 'http://127.0.0.1:9',
            'AWS_MAX_ATTEMPTS' => '1', 'COVERAGE_COMMAND' => "boot #{name}" }
    _out, err, status = Open3.capture3(env, RbConfig.ruby, '-I', File.expand_path('../boot', __dir__), script)

    refute status.success?
    assert_match(/NetworkingError|Failed to open TCP connection/, err)
  end
end
