# 導入

Redmine AWS SSM を使う Redmine に必要なもの (インストール、設定、前提とする AWS リソース、IAM 権限、ネットワーク) です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作成します。このページは、手作業で用意するときや、Serverless が作成するものを確認するときのためのものです。

<a id="requirements"></a>

## 動作環境

- Ruby 4.0 以降で動く Redmine 7.0 以降。
- SSM を呼び出せる AWS の認証情報を持つプロセス (Lambda では実行ロール、それ以外ではインスタンスプロファイルやタスクロール)。

<a id="installation"></a>

## インストール

1. プラグインを `plugins/redmine_aws_ssm` に、このプラグインが必要とする [Redmine AWS](https://redmine-kit.github.io/redmine_aws/ja/) を `plugins/redmine_aws` に置きます。gem をインストールするか ([gem](#gem))、リポジトリをクローンします ([gem を使わないとき](#without-the-gem))。Redmine はプラグインをアルファベット順に読み込むので、`redmine_aws` が先になります。
2. どちらの場合も、プラグインは `Gemfile.local` に gem として追加します。この行によって、Rails が設定を読み込む前に Bundler がプラグインを読み込みます ([README.md](README.md#when-it-reads))。
3. migration は不要です。

<a id="gem"></a>

### gem

バージョンのタグごとに、プラグインを gem として GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`) に公開します。GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` の権限を持つ GitHub のトークンが必要です。gem には、実行に必要なファイルが入ります。gem は `redmine_aws` の gem に依存するので、Bundler が同じソースからいっしょにインストールします。Redmine は `plugins/` のプラグインだけを読み込むので、インストールした 2 つの gem をそこにリンクします。

```ruby
# Redmine の Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_aws_ssm'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <ユーザー>:<トークン>   # か、変数 BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_aws)" plugins/redmine_aws
ln -s "$(bundle info --path redmine_aws_ssm)" plugins/redmine_aws_ssm
```

<a id="without-the-gem"></a>

### gem を使わないとき

リポジトリを `plugins/redmine_aws` と `plugins/redmine_aws_ssm` にクローンします。

```sh
git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_aws
git clone https://github.com/redmine-kit/redmine_aws_ssm.git plugins/redmine_aws_ssm
```

プラグインを、パスを指定した gem として `Gemfile.local` に追加し (プラグインの `Gemfile` に書かない理由は [README.md](README.md#when-it-reads))、gem をインストールします。gemspec が必要とする `redmine_aws` も Bundler が見つけられるように、パスで追加します。これは Bundler には読み込ませません (`require: false`。Redmine がプラグインとして読み込みます)。ほかの Redmine AWS のプラグインをパスで追加するときも、`redmine_aws` の行は 1 つだけにします。

```ruby
# Redmine の Gemfile.local
gem 'redmine_aws', path: 'plugins/redmine_aws', require: false
gem 'redmine_aws_ssm', path: 'plugins/redmine_aws_ssm'
```

```sh
bundle install
```

<a id="configuration"></a>

## 設定

| キー | 説明 | パラメーター |
| --- | --- | --- |
| `REDMINE_SSM_PATH` | このパスの下のパラメーターを環境変数に読み込む。なければ何も読み込まない | 必須。例: `/redmine/env/`。Rails を起動するすべてのプロセス (web、ジョブ、rake、`rails runner`) に設定する |

<a id="aws-resources"></a>

## AWS リソース

| リソース | 設定 |
| --- | --- |
| パスの下の SSM パラメーター | シークレットでない設定 (`REDMINE_DB_HOST` など) は `String`、シークレット (`SECRET_KEY_BASE`、`REDMINE_DB_PASSWORD` など) は `SecureString`。プラグインは読み込むだけで、作成するのはデプロイ |

<a id="iam-permissions"></a>

## IAM 権限

プラグインに必要な権限とポリシーの例は、[iam.md](iam.md) にあります。

<a id="network"></a>

## ネットワーク

| 送信先 | API | インターネットに接続できない VPC では |
| --- | --- | --- |
| SSM | `GetParametersByPath` | インターフェイスエンドポイント `com.amazonaws.<region>.ssm` |

呼び出しは、各プロセスの起動時に 1 回です。エンドポイントに接続できなければ、起動が失敗します。

<a id="tests"></a>

## テスト

`bin/test` は、Docker でテストを実行します。SSM は、`LOCALSTACK_AUTH_TOKEN` があれば LocalStack、なければ moto です (どちらを使うかを表示します)。ローダーが読み込む活用形を持つ Redmine AWS は、隣のチェックアウト (`../redmine_aws`) か、`REDMINE_AWS_DIR` のディレクトリから使います。CI は、push のたびに組織の LocalStack のトークンで実行し (フォークからの Pull Request は moto)、`boot/` のカバレッジを Codecov に送信します。

| テスト | 確認すること |
| --- | --- |
| `test/loader_test.rb` | 10 件を超えるパラメーター (複数のページ)、`SecureString` の復号、設定済みの環境変数、環境変数名にできない名前、下の階層、最後の `/` がないパス、接続できないエンドポイント |
| `test/boot_test.rb` | Redmine と同じ形で定義した Rails 8.1 のアプリケーションを、`REDMINE_SSM_PATH` を設定して別のプロセスで起動する。アプリケーションクラスの本体 (Redmine が `config/additional_environment.rb` を評価するところ) と `config/database.yml` で、Parameter Store の値が環境変数になっていること。パスがなければ何も読み込まないこと。Parameter Store に接続できなければ起動が失敗すること。ローダーが Redmine AWS の活用形 (`redmine_aws/inflections`) を読み込んでいること |
| `test/namespace_test.rb` | コードローダーを Redmine 7.0 と同じ形 (プラグインの `lib/` をルートディレクトリにし、イニシャライザーで新しいインフレクタを設定する) にした Rails 8.1 のアプリケーションを、boot ファイルを先に読み込んで別のプロセスで起動する。ローダーが、別のプラグインの `lib/redmine_aws/` のファイルを Redmine AWS の活用形で名付けること (`costexplorer.rb` は `RedmineAws::CostExplorer`)。`RedmineAws` を先に定義しても、Redmine AWS 自身のファイルを読み込めること |

Serverless も、イメージの中で `test/loader_test.rb` を実行します (`bin/test-image`)。そこでは、3 つの役割が、データベースのホスト、そのパスワード、`SECRET_KEY_BASE` を Parameter Store だけから読み込みます ([Serverless の testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#image-tests))。

<a id="to-verify"></a>

## 未確認の事項

- デフォルトのキー `aws/ssm` で、IAM が `kms:Decrypt` を許可する必要があるか
