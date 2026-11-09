# Redmine Serverless SSM

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_serverless_ssm/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_serverless_ssm/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_serverless_ssm)](https://codecov.io/gh/redmine-kit/redmine_serverless_ssm)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_serverless_ssm)](LICENSE)

A Redmine plugin that reads settings and secrets from AWS Systems Manager Parameter Store into environment variables before Rails starts, so that `config/database.yml` and `SECRET_KEY_BASE` can use them. It is part of [Serverless](https://github.com/redmine-kit/serverless), and works on any Redmine with AWS credentials.

[日本語](README.ja.md)

> **Status:** early development. The loading is implemented, tested against moto and LocalStack, and used in Serverless's image.

## Documentation

- Website: https://redmine-kit.github.io/redmine_serverless_ssm/ (日本語: https://redmine-kit.github.io/redmine_serverless_ssm/ja/)
- Markdown: [docs/README.md](docs/README.md) (日本語: [docs/ja/README.md](docs/ja/README.md)), with [setup](docs/setup.md) and [IAM permissions](docs/iam.md)

## License

Redmine Serverless SSM is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](LICENSE). Not affiliated with the Redmine project.
