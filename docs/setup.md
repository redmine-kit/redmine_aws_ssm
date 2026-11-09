# Setup

What a Redmine needs to use Redmine Serverless SSM: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later on Ruby 4.0 or later.
- A process with AWS credentials that can call SSM (an execution role on Lambda, an instance profile or a task role elsewhere).

## Installation

1. Put the plugin in `plugins/redmine_serverless_ssm`: install the gem ([Gem](#gem)) or clone the repository ([Without the gem](#without-the-gem)).
2. Either way, the plugin is a gem line in `Gemfile.local`. That line makes Bundler load the plugin before Rails reads the configuration ([README.md](README.md#when-it-reads)).
3. No migration is needed.

### Gem

Each version tag publishes the plugin as a gem to GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`). Installing from GitHub Packages needs a GitHub token with `read:packages`, even for a public package. The gem holds the plugin's run-time files. Redmine loads plugins only from `plugins/`, so the installed gem is linked there:

```ruby
# Redmine's Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_serverless_ssm'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <user>:<token>   # or the variable BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_serverless_ssm)" plugins/redmine_serverless_ssm
```

### Without the gem

Clone the repository into `plugins/redmine_serverless_ssm`:

```sh
git clone https://github.com/redmine-kit/redmine_serverless_ssm.git plugins/redmine_serverless_ssm
```

Add it as a path gem in `Gemfile.local` (not in the plugin's `Gemfile`, for the reason in [README.md](README.md#when-it-reads)), then install the gems:

```ruby
# Redmine's Gemfile.local
gem 'redmine_serverless_ssm', path: 'plugins/redmine_serverless_ssm'
```

```sh
bundle install
```

## Configuration

| Setting | Where | Contents |
| --- | --- | --- |
| `REDMINE_SSM_PATH` | Environment variable of every process that starts Rails (web, jobs, rake, `rails runner`) | The path whose parameters are read, for example `/redmine/env/`. Without it, nothing is read |

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

`bin/test` runs the tests in Docker, against SSM from LocalStack when `LOCALSTACK_AUTH_TOKEN` is set and from moto otherwise (it prints which). CI runs it on every push, with the organization's LocalStack token (pull requests from forks get moto), and sends the coverage of `boot/` to Codecov.

- **The loader (`test/loader_test.rb`):** more than 10 parameters (several pages), `SecureString` decryption, variables that are already set, names that cannot be variables and deeper paths, and an unreachable endpoint.
- **The boot (`test/boot_test.rb`):** a Rails 8.1 application, defined as Redmine's is, starts in a process of its own with `REDMINE_SSM_PATH`. The values from Parameter Store are in the environment in the application's class body (where Redmine evaluates `config/additional_environment.rb`) and in `config/database.yml`; without the path nothing is read; and start-up fails when Parameter Store cannot be reached.
- **In Serverless:** Serverless also runs `test/loader_test.rb` inside its image (`bin/test-image`), where the three roles read the database host, its password and `SECRET_KEY_BASE` only from Parameter Store ([Serverless testing.md](https://redmine-kit.github.io/serverless/testing.html#image-tests)).

## To verify

- Whether IAM must allow `kms:Decrypt` with the default key `aws/ssm`
