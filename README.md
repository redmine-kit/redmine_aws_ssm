# Redmine AWS SSM

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_aws_ssm/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_aws_ssm/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_aws_ssm?label=Coverage)](https://codecov.io/gh/redmine-kit/redmine_aws_ssm)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_aws_ssm?label=License)](LICENSE)
[![Tested with AWS Emulator](https://img.shields.io/badge/Tested%20with-AWS%20Emulator-232F3E)](https://github.com/aws/aws-emulator)

A Redmine plugin that reads settings and secrets from AWS Systems Manager Parameter Store into environment variables before Rails starts, so that `config/database.yml` and `SECRET_KEY_BASE` can use them. It requires [Redmine AWS](https://github.com/redmine-kit/redmine_aws), which holds the "AWS" administration menu. It is part of [Serverless](https://github.com/redmine-kit/serverless), and works on any Redmine with AWS credentials.

[日本語](README.ja.md)

> **Status:** early development. It is implemented and tested on Redmine 7.0.3. It is used in Serverless's image.

## Documentation

- Website: https://redmine-kit.github.io/redmine_aws_ssm/ (日本語: https://redmine-kit.github.io/redmine_aws_ssm/ja/)
- Markdown: [docs/README.md](docs/README.md) (日本語: [docs/ja/README.md](docs/ja/README.md)), with [setup](docs/setup.md) and [IAM permissions](docs/iam.md)

## Sponsors

<a href="https://www.keyselect.co.jp/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keyselect-logo-dark.svg">
    <img alt="KEY SELECT" src=".github/assets/keyselect-logo.svg" width="136" height="29">
  </picture>
</a>

## License

Redmine AWS SSM is released under the GNU General Public License, version 2 or (at your option) any later version. See [LICENSE](LICENSE). An unofficial Redmine plugin.
