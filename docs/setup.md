# Setup

What a Redmine needs to use Redmine Serverless SSM: installation, configuration, the AWS resources it expects, IAM permissions and network access. [Serverless](https://redmine-kit.github.io/serverless/) sets all of this up with CloudFormation; this page is for setting it up by hand, or for checking what Serverless creates.

## Requirements

- Redmine 7.0 or later on Ruby 4.0 or later.
- A process with AWS credentials that can call SSM (an execution role on Lambda, an instance profile or a task role elsewhere).

## Installation

**Getting the plugin:** with Docker, copy it from the plugin's image on ghcr.io, pinned by digest (tags: `main` and `sha-<commit>` for every push to `main`, `v*` for releases):

```dockerfile
COPY --from=ghcr.io/redmine-kit/redmine_serverless_ssm:main@sha256:<digest> /redmine_serverless_ssm plugins/redmine_serverless_ssm/
```

Without Docker, clone the repository (`git clone https://github.com/redmine-kit/redmine_serverless_ssm.git plugins/redmine_serverless_ssm`) or, once releases are published, extract a release archive into `plugins/redmine_serverless_ssm`.

1. Put the plugin in `plugins/redmine_serverless_ssm`.
2. Add this line to Redmine's `Gemfile.local`, and run `bundle install` ([README.md](README.md#when-it-reads) explains why the line is not in the plugin's `Gemfile`):

```ruby
gem 'redmine_serverless_ssm', path: 'plugins/redmine_serverless_ssm'
```

3. No migration is needed.

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

`test/loader_test.rb` runs against moto, which reproduces the SSM API. Serverless runs it inside its image (`bin/test-image`), where the three roles also read the database host, its password and `SECRET_KEY_BASE` only from Parameter Store, which checks the timing.

## To verify

- Whether IAM must allow `kms:Decrypt` with the default key `aws/ssm`
