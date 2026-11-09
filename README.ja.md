# Redmine Serverless SSM

Rails が起動する前に、AWS Systems Manager Parameter Store から設定と秘密の値を環境変数に読み込み、`config/database.yml` と `SECRET_KEY_BASE` で使えるようにする Redmine のプラグインです。[Serverless](https://github.com/redmine-kit/serverless) の一部で、AWS の認証情報がある Redmine なら、どこでも動きます。

[English](README.md)

## 資料

- Web サイト: https://redmine-kit.github.io/redmine_serverless_ssm/ja/ (English: https://redmine-kit.github.io/redmine_serverless_ssm/)
- Markdown: [docs/ja/README.md](docs/ja/README.md) (English: [docs/README.md](docs/README.md))

## ライセンス

Redmine Serverless SSM は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](LICENSE) を参照してください。Redmine projectとは関係ありません。
