# Setup

What a Redmine server needs to use Redmine AWS SSM: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later, on Ruby 3.2 or later (Redmine 7.0 supports Ruby 3.2 to 4.0; the CI tests on both).
- A process with AWS credentials that can call SSM (an execution role on Lambda, an instance profile or a task role elsewhere).

## Installation

1. Put the plugin in `plugins/redmine_aws_ssm`, and [Redmine AWS](https://redmine-kit.github.io/redmine_aws/), which it requires, in `plugins/redmine_aws`: install the gem ([Gem](#gem)) or clone the repositories ([Without the gem](#without-the-gem)). Redmine loads plugins in alphabetical order, so `redmine_aws` comes first.
2. Either way, the plugin is a gem line in `Gemfile.local`. That line makes Bundler load the plugin before Rails reads the configuration ([README.md](README.md#when-it-reads)).
3. No migration is needed.

### Gem

Each version tag publishes the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`). Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package. The gem holds the plugin's run-time files. The gem depends on the gem `redmine_aws`, so Bundler installs it from the same source. Redmine loads plugins only from `plugins/`, so both installed gems are linked there:

```ruby
# Redmine's Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_aws_ssm'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <user>:<token>   # or the variable BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_aws)" plugins/redmine_aws
ln -s "$(bundle info --path redmine_aws_ssm)" plugins/redmine_aws_ssm
```

### Without the gem

Clone the repositories into `plugins/redmine_aws` and `plugins/redmine_aws_ssm`:

```sh
git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_aws
git clone https://github.com/redmine-kit/redmine_aws_ssm.git plugins/redmine_aws_ssm
```

Add it as a path gem in `Gemfile.local` (not in the plugin's `Gemfile`, for the reason in [README.md](README.md#when-it-reads)), then install the gems. Bundler must also find `redmine_aws`, which the gemspec requires, so it is added by path too, without loading it (`require: false`; Redmine loads it as a plugin). List it once, however many Redmine AWS plugins are added by path:

```ruby
# Redmine's Gemfile.local
gem 'redmine_aws', path: 'plugins/redmine_aws', require: false
gem 'redmine_aws_ssm', path: 'plugins/redmine_aws_ssm'
```

```sh
bundle install
```

## Configuration

| Key | Description | Parameter |
| --- | --- | --- |
| `REDMINE_SSM_PATH` | Reads the parameters under this path into environment variables. Without it, nothing is read | Required. Example: `/redmine/env/`. Set it in every process that starts Rails (web, jobs, rake, `rails runner`) |

## AWS resources

| Resource | Settings |
| --- | --- |
| SSM parameters under the path | `String` for settings that are not secret (such as `REDMINE_DB_HOST`), `SecureString` for secrets (such as `SECRET_KEY_BASE` and `REDMINE_DB_PASSWORD`). The plugin only reads them; the deployment creates them |

## IAM permissions

The permissions the plugin needs, with an example policy, are in [iam.md](iam.md).

## Network

| Destination | API | In a VPC without internet access |
| --- | --- | --- |
| SSM | `GetParametersByPath` | Interface endpoint `com.amazonaws.<region>.ssm` |

The call is made once when each process starts. If the endpoint cannot be reached, start-up fails.

## Tests

`bin/test` runs the tests in Docker, against SSM from LocalStack when `LOCALSTACK_AUTH_TOKEN` is set and from moto otherwise (it prints which), with Redmine AWS, whose inflections the loader requires, from a checkout next to this one (`../redmine_aws`) or from the directory in `REDMINE_AWS_DIR`. CI runs the tests and the lint on every push, on Ruby 3.2 and 4.0. The tests use the organization's LocalStack token (pull requests from forks get moto), and CI sends the coverage of `boot/` to Codecov. Locally, `TEST_RUBY=3.2 bin/test` (or `bin/lint`) runs them on Ruby 3.2.

| Test | What it checks |
| --- | --- |
| `test/loader_test.rb` | More than 10 parameters (several pages), `SecureString` decryption, variables that are already set, names that cannot be variables, deeper paths, a path without the last `/`, and an unreachable endpoint |
| `test/boot_test.rb` | A Rails 8.1 application, defined as Redmine's is, starts in a process of its own with `REDMINE_SSM_PATH`. The values from Parameter Store are in the environment in the application's class body (where Redmine evaluates `config/additional_environment.rb`) and in `config/database.yml`; without the path nothing is read; start-up fails when Parameter Store cannot be reached; the loader has required Redmine AWS's inflections (`redmine_aws/inflections`) |
| `test/namespace_test.rb` | A Rails 8.1 application whose code loader is set up as Redmine 7.0's (the plugins' `lib/` as root directories, a new inflector given in an initializer) starts in a process of its own with the boot file loaded first. The loader names the files of another plugin under `lib/redmine_aws/` with Redmine AWS's inflections (`costexplorer.rb` is `RedmineAws::CostExplorer`), and Redmine AWS's own files load after `RedmineAws` was defined early |

Serverless also runs `test/loader_test.rb` inside its image (`bin/test-image`). There, the three roles read the database host, its password and `SECRET_KEY_BASE` only from Parameter Store ([Serverless testing.md](https://redmine-kit.github.io/serverless/testing.html#image-tests)).

## To verify

- Whether IAM must allow `kms:Decrypt` with the default key `aws/ssm`
