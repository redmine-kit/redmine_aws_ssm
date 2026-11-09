# 準備

Redmine Serverless SSM を使う Redmine に要るもの(インストール、設定、前提にする AWS のリソース、IAM の権限、ネットワーク)です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作ります。このページは、手で用意するときや、Serverless が作るものを確認するときのためのものです。

<a id="requirements"></a>

## 前提

- Ruby 4.0 以降の上の Redmine 7.0 以降。
- SSM を呼べる AWS の認証情報を持つプロセス(Lambda では実行ロール、ほかではインスタンスプロファイルやタスクのロール)。

<a id="installation"></a>

## インストール

**プラグインの取り方:** バージョンのタグごとに、プラグインを gem として GitHub Packages(`https://rubygems.pkg.github.com/redmine-kit`)に公開します。GitHub Packages から入れるには、公開のパッケージでも、`read:packages` の権限を持つ GitHub のトークンが要ります。gem はプラグインの動かすためのファイルを持ちます。Redmine は `plugins/` のプラグインだけを読み込むので、入れた gem をそこにリンクします。

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

gem を使わないなら、リポジトリを `plugins/redmine_serverless_ssm` に clone します(`git clone https://github.com/redmine-kit/redmine_serverless_ssm.git plugins/redmine_serverless_ssm`)。

1. 上のとおり gem を入れて、`plugins/redmine_serverless_ssm` にリンクします。`Gemfile.local` の gem の行が、Rails が設定を読む前に、Bundler にプラグインを読み込ませます([README.md](README.md#when-it-reads))。
2. gem の代わりに clone したときは、`Gemfile.local` で、プラグインを道筋を指定した gem として足し(プラグインの `Gemfile` に置かない理由は [README.md](README.md#when-it-reads))、`bundle install` を実行します。

```ruby
gem 'redmine_serverless_ssm', path: 'plugins/redmine_serverless_ssm'
```

3. migration は要りません。

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

`test/loader_test.rb` は、SSM の API を再現する moto に対して動きます。Serverless が、イメージの中で実行します(`bin/test-image`)。そこでは、3 つの役割が、データベースのホスト、そのパスワード、`SECRET_KEY_BASE` を Parameter Store だけから読むので、読み込みのタイミングも確認できます。

<a id="to-verify"></a>

## 確認すること

- 既定の鍵 `aws/ssm` で、IAM が `kms:Decrypt` を許す必要があるか
