# Redmine AWS SSM

[![CI](https://img.shields.io/github/actions/workflow/status/redmine-kit/redmine_aws_ssm/ci.yml?branch=main&label=CI)](https://github.com/redmine-kit/redmine_aws_ssm/actions/workflows/ci.yml)
[![Coverage](https://img.shields.io/codecov/c/github/redmine-kit/redmine_aws_ssm?label=Coverage)](https://codecov.io/gh/redmine-kit/redmine_aws_ssm)
[![License](https://img.shields.io/github/license/redmine-kit/redmine_aws_ssm?label=License)](LICENSE)
[![Tested with AWS Emulator](https://img.shields.io/badge/Tested%20with-AWS%20Emulator-232F3E)](https://github.com/aws/aws-emulator)

Rails が起動する前に、AWS Systems Manager Parameter Store から設定とシークレットを環境変数に読み込み、`config/database.yml` と `SECRET_KEY_BASE` で使えるようにする Redmine のプラグインです。「AWS」の管理メニューを持つ [Redmine AWS](https://github.com/redmine-kit/redmine_aws) を必要とします。[Serverless](https://github.com/redmine-kit/serverless) の一部で、AWS の認証情報がある Redmine なら、どこでも動きます。

[English](README.md)

> **状態:** 開発の初期です。実装し、Redmine 7.0.3 でテストしています。Serverless のイメージで使っています。

<a id="documentation"></a>

## ドキュメント

- Web サイト: https://redmine-kit.github.io/redmine_aws_ssm/ja/ (English: https://redmine-kit.github.io/redmine_aws_ssm/)
- Markdown: [docs/ja/README.md](docs/ja/README.md) (English: [docs/README.md](docs/README.md))。[導入](docs/ja/setup.md)、[IAM 権限](docs/ja/iam.md) があります。

<a id="sponsors"></a>

## スポンサー

<a href="https://www.keyselect.co.jp/">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/assets/keyselect-logo-dark.svg">
    <img alt="KEY SELECT" src=".github/assets/keyselect-logo.svg" width="136" height="29">
  </picture>
</a>

<a id="license"></a>

## ライセンス

Redmine AWS SSM は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](LICENSE) を参照してください。Redmine の非公式のプラグインです。
