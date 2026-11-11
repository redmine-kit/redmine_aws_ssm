# frozen_string_literal: true

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
      # environment variables are skipped. Returns the names read, in order.
      def load(path, client: ::Aws::SSM::Client.new)
        names = []
        client.get_parameters_by_path(path: path, recursive: false, with_decryption: true).each_page do |page|
          page.parameters.each do |parameter|
            name = parameter.name.delete_prefix(path)
            next unless NAME.match?(name)

            names << name
            ENV[name] ||= parameter.value
          end
        end
        names
      end
    end
  end
end
