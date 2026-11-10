# Redmine Serverless SSM

Redmine Serverless SSM (`redmine_serverless_ssm`) is a Redmine plugin that reads settings and secrets from AWS Systems Manager Parameter Store into environment variables before Rails starts. [Serverless](https://redmine-kit.github.io/serverless/lambda.html#settings-and-secrets-ssm-parameter-store) installs it in the Lambda image, and it works the same way on any Redmine that has AWS credentials (containers, virtual machines). It does not modify Redmine's own files. The plugin is in early development: the loading is implemented and tested in Serverless's image.

- [Setup](setup.md): requirements, installation, configuration, AWS resources, network, tests
- [IAM permissions](iam.md): permissions, example policy, resource-based policies

## Features

| Feature | Contents | Enabled when | Page |
| --- | --- | --- | --- |
| Settings from Parameter Store | Reads every parameter directly under one path into environment variables, before Rails reads `config/database.yml` and `SECRET_KEY_BASE` | `REDMINE_SSM_PATH` is set | [setup.md](setup.md#configuration) |
| Names on the administration page | `RedmineServerlessSsm.loaded` holds the names read (not the values); [Redmine Serverless](https://redmine-kit.github.io/redmine_serverless/admin.html#status-and-connections) shows them on the "Status" tab | Same as above | — |

- **Reads one path:** It reads the parameters directly under `REDMINE_SSM_PATH` (for example `/redmine/env/`) with `GetParametersByPath`, continuing past the 10 parameters of one call, and decrypts `SecureString` parameters.
- **Names become variables:** The last part of each name is the variable name: `/redmine/env/SECRET_KEY_BASE` becomes `SECRET_KEY_BASE`. Only names that can be environment variables (capital letters, digits and `_`) are read, and deeper paths are not.
- **Variables that are set are kept:** A variable that already exists is not replaced, so that local tests can pass values directly.
- **Fails early:** If Parameter Store cannot be reached, Redmine does not start, instead of starting without its secrets.

## When it reads

The parameters must be in the environment before Rails reads `config/database.yml` (the database host and password) and `SECRET_KEY_BASE`. A plugin's `init.rb` runs much later, when Redmine prepares its code, so the reading is not in `init.rb`.

1. Redmine's `Gemfile.local` adds the plugin as a gem by path (`redmine_serverless_ssm.gemspec`). The plugin's own `Gemfile` cannot do it: Bundler would write the path to `Gemfile.lock` relative to the plugin's directory, and read it back relative to Redmine's.
2. `Bundler.require` in `config/application.rb` loads `boot/redmine_serverless_ssm.rb`.
3. When the application class is defined, its Railtie's `before_configuration` reads the parameters. This is before the class body (including `config/additional_environment.rb`) and before `config/database.yml` is read.

The code is in `boot/`, not `lib/`: Redmine adds a plugin's `lib/` to the autoloaded paths, and a file that Bundler has already required must not be autoloaded again. `init.rb` only registers the plugin, so that it is listed in the administration pages.

## Each process

Every process that loads the Rails environment reads the parameters once, when it starts: the web server, background jobs, `rake` and `rails runner`. A changed value therefore reaches only processes started after the change. On Lambda, these are new execution environments, for example after the function's configuration is updated.

The database gem is still chosen correctly when the host and password come from Parameter Store. Redmine's `Gemfile` picks it from the literal `adapter:` in `config/database.yml`, without evaluating the file.

If Parameter Store returns an error (no route, no permission), the plugin raises it and the process stops before Rails reads its configuration. Redmine never runs with only some of its values.

## Sponsors

<Sponsors><a href="https://www.keyselect.co.jp/">KEY SELECT</a> <a href="https://localstack.cloud">LocalStack</a></Sponsors>

## License

Redmine Serverless SSM is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](../LICENSE). An unofficial Redmine plugin.
