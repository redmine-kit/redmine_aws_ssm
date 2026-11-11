# frozen_string_literal: true

# Loaded by the tests that bin/test runs. The tests reach SSM at
# AWS_ENDPOINT_URL (moto or LocalStack).
require_relative 'coverage'
require 'minitest/autorun'
require 'securerandom'
require 'redmine_aws_ssm/loader'
