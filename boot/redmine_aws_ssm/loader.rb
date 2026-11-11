# frozen_string_literal: true

# The constant names of the Redmine AWS plugins' files (lib/redmine_aws/ses.rb
# defines RedmineAws::SES), from redmine_aws. Required before RedmineAws is
# defined here: Rails' code loader then names those files when it sets up,
# before redmine_aws's init.rb runs.
require 'redmine_aws/inflections'
require 'aws-sdk-ssm'

# RedmineAws is the namespace of the Redmine AWS plugins. redmine_aws defines
# it in its lib/redmine_aws.rb, which Redmine loads only after this file:
# Bundler loads boot/ before Rails initializes. So this file opens the module
# with nothing in it but RedmineAws::SSM, and redmine_aws loads its file
# explicitly from its init.rb.
module RedmineAws
  module SSM
    class << self
      # The names read at start-up, for the Status tab of redmine_aws.
      attr_accessor :loaded
    end
    self.loaded = []

    # Reads parameters from SSM Parameter Store into ENV.
    module Loader
      NAME = /\A[A-Z][A-Z0-9_]*\z/

      module_function

      # Reads every parameter directly under path (such as /redmine/env/) into
      # ENV, with the last part of the name as the variable name, and decrypts
      # SecureString parameters. Variables that are already set are kept, so
      # that local tests can pass values directly. Names that cannot be
      # environment variables are skipped. Returns the names it set, in order:
      # not the kept ones, whose values did not come from Parameter Store.
      # The path may end with / or not, as Parameter Store accepts both.
      def load(path, client: ::Aws::SSM::Client.new)
        prefix = path.end_with?('/') ? path : "#{path}/"
        parameters(path, client).filter_map do |parameter|
          name = parameter.name.delete_prefix(prefix)
          next if !NAME.match?(name) || ENV.key?(name)

          ENV[name] = parameter.value
          name
        end
      end

      # The parameters directly under path, decrypted, from every page.
      def parameters(path, client)
        pages = client.get_parameters_by_path(path: path, recursive: false, with_decryption: true).each_page
        pages.flat_map(&:parameters)
      end
    end
  end
end
