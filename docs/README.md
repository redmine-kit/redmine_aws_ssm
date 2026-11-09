# Redmine Serverless SSM

Redmine Serverless SSM (`redmine_serverless_ssm`) is a Redmine plugin that reads settings and secrets from AWS Systems Manager Parameter Store into environment variables before Rails starts. It is used by [Serverless](https://redmine-kit.github.io/serverless/lambda.html#settings-and-secrets-ssm-parameter-store), which runs Redmine on AWS Lambda, and works the same way on any Redmine that has AWS credentials (containers, virtual machines).

## What it does

- **Reads one path:** With the environment variable `REDMINE_SSM_PATH` set (for example `/redmine/env/`), it reads every parameter directly under that path with `GetParametersByPath`, continuing past the 10 parameters of one call, and decrypts `SecureString` parameters.
- **Names become variables:** The last part of each name is the variable name: `/redmine/env/SECRET_KEY_BASE` becomes `SECRET_KEY_BASE`. Only names that can be environment variables (capital letters, digits and `_`) are read, and deeper paths are not.
- **Variables that are set are kept:** A variable that already exists is not replaced, so that local tests can pass values directly.
- **Fails early:** If Parameter Store cannot be reached, Redmine does not start, instead of starting without its secrets.
- **Off without the path:** Without `REDMINE_SSM_PATH`, nothing is read.

## When it reads

The parameters must be in the environment before Rails reads `config/database.yml` (the database host and password) and `SECRET_KEY_BASE`. A plugin's `init.rb` runs much later, when Redmine prepares its code, so the reading is not in `init.rb`.

1. Redmine's `Gemfile.local` adds the plugin as a gem by path (`redmine_serverless_ssm.gemspec`). The plugin's own `Gemfile` cannot do it: Bundler would write the path to `Gemfile.lock` relative to the plugin's directory, and read it back relative to Redmine's.
2. `Bundler.require` in `config/application.rb` loads `boot/redmine_serverless_ssm.rb`.
3. When the application class is defined, its Railtie's `before_configuration` reads the parameters. This is before the class body (including `config/additional_environment.rb`) and before `config/database.yml` is read.

The code is in `boot/`, not `lib/`: Redmine adds a plugin's `lib/` to the autoloaded paths, and a file that Bundler has already required must not be autoloaded again. `init.rb` only registers the plugin, so that it is listed in the administration pages. `RedmineServerlessSsm.loaded` holds the names read, for the administration pages.

## Installation

Put the plugin in `plugins/redmine_serverless_ssm`, add this line to Redmine's `Gemfile.local`, and run `bundle install`:

```ruby
gem 'redmine_serverless_ssm', path: 'plugins/redmine_serverless_ssm'
```

 Set `REDMINE_SSM_PATH`, and give the process the permissions below ([IAM permissions](#iam-permissions)).

## IAM permissions

| Permission | Resource | Use |
| --- | --- | --- |
| `ssm:GetParametersByPath` | `arn:aws:ssm:<region>:<account>:parameter/<instance>/env` and below it | Reading the parameters under `REDMINE_SSM_PATH` |
| `kms:Decrypt` | The key that encrypts the `SecureString` parameters | Decrypting them. With the default key `aws/ssm`, whether IAM must allow it is not checked yet; with a customer managed key, the key policy must allow it too |

Example policy, for `REDMINE_SSM_PATH=/<instance>/env/`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSettings",
      "Effect": "Allow",
      "Action": "ssm:GetParametersByPath",
      "Resource": [
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env",
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env/*"
      ]
    },
    {
      "Sid": "DecryptSettings",
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "*",
      "Condition": { "StringEquals": { "kms:ViaService": "ssm.<region>.amazonaws.com" } }
    }
  ]
}
```

- **Who reads:** Every process that starts Rails with the plugin (web, jobs, rake, `rails runner`) reads the parameters, so each of their roles needs the permissions.
- **Who writes:** The plugin only reads. The parameters are created by the deployment: `String` for settings that are not secret, `SecureString` for secrets such as `SECRET_KEY_BASE` and the database password.

## Network

| To | API | In a VPC without internet access |
| --- | --- | --- |
| SSM | `GetParametersByPath` | Interface endpoint `com.amazonaws.<region>.ssm` |

The call is made once when each process starts. If the endpoint cannot be reached, start-up fails.

## Tests

`test/loader_test.rb` runs against moto, which reproduces the SSM API. Serverless runs it inside its image (`bin/test-image`), where the three roles also read the database host, its password and `SECRET_KEY_BASE` only from Parameter Store, which checks the timing.
