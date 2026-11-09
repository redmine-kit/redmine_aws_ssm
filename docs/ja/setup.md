# 準備

Redmine Serverless SSM を使う Redmine に要るもの(インストール、設定、前提にする AWS のリソース、IAM の権限、ネットワーク)です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作ります。このページは、手で用意するときや、Serverless が作るものを確認するときのためのものです。

<a id="requirements"></a>

## 前提

- Ruby 4.0 以降の上の Redmine 7.0 以降。
- SSM を呼べる AWS の認証情報を持つプロセス(Lambda では実行ロール、ほかではインスタンスプロファイルやタスクのロール)。

<a id="installation"></a>

## インストール

1. プラグインを `plugins/redmine_serverless_ssm` に置きます。gem をインストールするか([gem](#gem))、リポジトリをクローンします([gem を使わないとき](#without-the-gem))。
2. どちらでも、プラグインは `Gemfile.local` の gem の行になります。この行が、Rails が設定を読む前に、Bundler にプラグインを読み込ませます([README.md](README.md#when-it-reads))。
3. migration は要りません。

<a id="gem"></a>

### gem

バージョンのタグごとに、プラグインを gem として GitHub Packages(`https://rubygems.pkg.github.com/redmine-kit`)に公開します。GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` の権限を持つ GitHub のトークンが要ります。gem は、プラグインを動かすためのファイルを持ちます。Redmine は `plugins/` のプラグインだけを読み込むので、インストールした gem をそこにリンクします。

```ruby
# Redmine の Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_serverless_ssm'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <ユーザー>:<トークン>   # か、変数 BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_serverless_ssm)" plugins/redmine_serverless_ssm
```

<a id="without-the-gem"></a>

### gem を使わないとき

リポジトリを `plugins/redmine_serverless_ssm` にクローンします。

```sh
git clone https://github.com/redmine-kit/redmine_serverless_ssm.git plugins/redmine_serverless_ssm
```

`Gemfile.local` に、パスを指定した gem として足し(プラグインの `Gemfile` に置かない理由は [README.md](README.md#when-it-reads))、gem をインストールします。

```ruby
# Redmine の Gemfile.local
gem 'redmine_serverless_ssm', path: 'plugins/redmine_serverless_ssm'
```

```sh
bundle install
```

<a id="configuration"></a>

## 設定

| 設定 | 場所 | 中身 |
| --- | --- | --- |
| `REDMINE_SSM_PATH` | Rails を起動するすべてのプロセス(web、ジョブ、rake、`rails runner`)の環境変数 | 読むパラメーターの道筋。例: `/redmine/env/`。なければ何も読まない |

<a id="aws-resources"></a>

## AWS のリソース

| リソース | 設定 |
| --- | --- |
| 道筋の下の SSM のパラメーター | 秘密でない設定(`REDMINE_DB_HOST` など)は `String`、秘密の値(`SECRET_KEY_BASE`、`REDMINE_DB_PASSWORD` など)は `SecureString`。プラグインは読むだけで、作るのはデプロイ |

<a id="iam-permissions"></a>

## IAM の権限

プラグインに要る権限と例のポリシーは、[iam.md](iam.md) にあります。

<a id="network"></a>

## ネットワーク

| 行き先 | API | インターネットに出られない VPC の中では |
| --- | --- | --- |
| SSM | `GetParametersByPath` | インターフェースのエンドポイント `com.amazonaws.<region>.ssm` |

呼び出しは、プロセスが起動するときに 1 回です。エンドポイントに届かなければ、起動が失敗します。

<a id="tests"></a>

## テスト

`bin/test` が、Docker の中でテストを実行します。`LOCALSTACK_AUTH_TOKEN` があれば LocalStack の、なければ moto の SSM に対して動きます(どちらかを表示します)。CI は、push のたびに、組織の LocalStack のトークンで実行し(フォークからのプルリクエストは moto)、`boot/` のカバレッジを Codecov に送ります。

- **読み込み(`test/loader_test.rb`):** 10 件を超えるパラメーター(複数のページ)、`SecureString` の復号、すでにある環境変数、環境変数にできない名前と下の階層、届かないエンドポイント。
- **起動(`test/boot_test.rb`):** Redmine と同じ形で定義した Rails 8.1 のアプリを、`REDMINE_SSM_PATH` を付けて、別のプロセスで起動します。アプリのクラスの本体(Redmine が `config/additional_environment.rb` を評価するところ)と `config/database.yml` で、Parameter Store の値が環境に入っていること、道筋がなければ何も読まないこと、Parameter Store に届かなければ起動が失敗することを確認します。
- **Serverless で:** Serverless も、イメージの中で `test/loader_test.rb` を実行します(`bin/test-image`)。そこでは、3 つの役割が、データベースのホスト、そのパスワード、`SECRET_KEY_BASE` を Parameter Store だけから読みます([Serverless の testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#image-tests))。

<a id="to-verify"></a>

## 確認すること

- 既定の鍵 `aws/ssm` で、IAM が `kms:Decrypt` を許す必要があるか
