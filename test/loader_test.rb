# frozen_string_literal: true

# Runs against moto or LocalStack with bin/test, and inside the Serverless
# image (its bin/test-image), where the loader is required first:
#   ruby -rbundler/setup -rredmine_aws_ssm/loader loader_test.rb
require_relative 'test_helper'

class LoaderTest < Minitest::Test
  def setup
    @ssm = Aws::SSM::Client.new
    @path = "/env-test-#{SecureRandom.hex(4)}/env/"
    @saved = ENV.to_h
  end

  def teardown
    ENV.replace(@saved)
  end

  def put(name, value, type: 'String')
    @ssm.put_parameter(name: "#{@path}#{name}", value: value, type: type)
  end

  def test_reads_every_parameter_past_ten
    12.times { |i| put("SSM_ENV_TEST_#{i}", "value-#{i}") }

    names = RedmineAws::SSM::Loader.load(@path, client: @ssm)

    assert_equal 12, names.size
    assert_equal 'value-11', ENV.fetch('SSM_ENV_TEST_11')
  end

  def test_decrypts_secure_strings
    put('SSM_ENV_TEST_SECRET', 'secret-value', type: 'SecureString')
    RedmineAws::SSM::Loader.load(@path, client: @ssm)

    assert_equal 'secret-value', ENV.fetch('SSM_ENV_TEST_SECRET')
  end

  # A kept variable is not in the names: the Status tab of redmine_aws lists
  # them as read from Parameter Store.
  def test_keeps_variables_that_are_set_and_does_not_list_them
    ENV['SSM_ENV_TEST_KEPT'] = 'from the environment'
    put('SSM_ENV_TEST_KEPT', 'from SSM')
    put('SSM_ENV_TEST_SET', 'from SSM')
    names = RedmineAws::SSM::Loader.load(@path, client: @ssm)

    assert_equal 'from the environment', ENV.fetch('SSM_ENV_TEST_KEPT')
    assert_equal ['SSM_ENV_TEST_SET'], names
  end

  def test_skips_names_that_cannot_be_variables_and_deeper_paths
    put('lower_case', 'x')
    put('nested/SSM_ENV_TEST_DEEP', 'x')
    put('SSM_ENV_TEST_OK', 'x')

    assert_equal ['SSM_ENV_TEST_OK'], RedmineAws::SSM::Loader.load(@path, client: @ssm)
  end

  def test_reads_a_path_without_the_last_slash
    put('SSM_ENV_TEST_NO_SLASH', 'from SSM')

    assert_equal ['SSM_ENV_TEST_NO_SLASH'], RedmineAws::SSM::Loader.load(@path.delete_suffix('/'), client: @ssm)
    assert_equal 'from SSM', ENV.fetch('SSM_ENV_TEST_NO_SLASH')
  end

  def test_an_unreachable_service_fails
    client = Aws::SSM::Client.new(endpoint: 'http://127.0.0.1:9', retry_limit: 0, http_open_timeout: 1)

    assert_raises(Seahorse::Client::NetworkingError) { RedmineAws::SSM::Loader.load(@path, client: client) }
  end
end
