# frozen_string_literal: true

# Loaded by the tests that bin/test runs. The tests reach SSM at
# AWS_ENDPOINT_URL (AWS Emulator with bin/test).
require_relative 'coverage'
require 'minitest/autorun'
require 'securerandom'
require 'redmine_aws_ssm/loader'
