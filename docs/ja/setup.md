# 導入

Redmine Kit AWS SSM を使う Redmine に必要なもの (インストール、設定、前提とする AWS リソース、IAM 権限、ネットワーク) です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作成します。このページは、手作業で用意するときや、Serverless が作成するものを確認するときのためのものです。

<a id="requirements"></a>

## 動作環境

- Redmine 7.0 以降、Ruby 3.2 以降 (Redmine 7.0 が対応するのは Ruby 3.2 から 4.0。CI は両方でテストします)。
- SSM を呼び出せる AWS の認証情報を持つプロセス (Lambda では実行ロール、それ以外ではインスタンスプロファイルやタスクロール)。

<a id="required-plugins"></a>

### 必須プラグイン

| プラグイン | 用途 |
| --- | --- |
| [Redmine Kit AWS](https://github.com/redmine-kit/redmine_aws) | 「AWS」の管理メニューと、AWS のプラグインが共有する設定 |

ないときは、Redmine が起動時に停止し、そのプラグインの名前を示します。gem としてインストールすると、このプラグインがそれもインストールします ([インストール](#installation))。

<a id="optional-plugins"></a>

### オプションのプラグイン

| プラグイン | 使える機能 |
| --- | --- |
| [Redmine Kit Help](https://github.com/redmine-kit/redmine_help) | ヘルプのパネルに表示するこのプラグインのヘルプ |

<a id="installation"></a>

## インストール

1. プラグインを `plugins/redmine_kit_aws_ssm` に、このプラグインが必要とする [Redmine Kit AWS](https://redmine-kit.github.io/redmine_aws/ja/) を `plugins/redmine_kit_aws` に置きます。gem をインストールするか ([gem](#gem))、リポジトリをクローンします ([gem を使わないとき](#without-the-gem))。順序は問いません。`redmine_kit_aws` がないときは、Redmine が起動時に停止し、その名前を示します ([必須プラグイン](#required-plugins))。
2. どちらの場合も、プラグインは `Gemfile.local` に gem として追加します。この行によって、Rails が設定を読み込む前に Bundler がプラグインを読み込みます ([README.md](README.md#when-it-reads))。
3. migration は不要です。

<a id="gem"></a>

### gem

`bin/release` が、各バージョンのプラグインを gem として GitHub Packages (`https://rubygems.pkg.github.com/redmine-kit`。[リリース](#releasing)) に公開します。GitHub Packages からインストールするには、公開のパッケージでも、`read:packages` の権限を持つ GitHub のトークンが必要です。gem には、実行に必要なファイル (`init.rb`、`boot/`、`config/locales/`、`LICENSE`) と、テスト (`test/**/*.rb`) が入ります。テストは、Serverless が自身のイメージで実行します (`test/loader_test.rb`)。gem は `redmine_kit_aws` の gem に依存するので、Bundler が同じソースからいっしょにインストールします。Redmine は `plugins/` のプラグインだけを読み込むので、インストールした 2 つの gem をそこにリンクします。

```ruby
# Redmine の Gemfile.local
source 'https://rubygems.pkg.github.com/redmine-kit' do
  gem 'redmine_kit_aws_ssm'
end
```

```sh
bundle config set --global rubygems.pkg.github.com <ユーザー>:<トークン>   # か、変数 BUNDLE_RUBYGEMS__PKG__GITHUB__COM
bundle install
ln -s "$(bundle info --path redmine_kit_aws)" plugins/redmine_kit_aws
ln -s "$(bundle info --path redmine_kit_aws_ssm)" plugins/redmine_kit_aws_ssm
```

Bundler は、それぞれのリポジトリからもプラグインをインストールできます。この場合、トークンは不要です。`plugins/` へのリンクは上と同じです。

```ruby
# Redmine の Gemfile.local
gem 'redmine_kit_aws', git: 'https://github.com/redmine-kit/redmine_aws.git', tag: 'v0.1.0', require: false
gem 'redmine_kit_aws_ssm', git: 'https://github.com/redmine-kit/redmine_aws_ssm.git', tag: 'v0.1.0'
```

<a id="without-the-gem"></a>

### gem を使わないとき

リポジトリを `plugins/redmine_kit_aws` と `plugins/redmine_kit_aws_ssm` にクローンします。

```sh
git clone https://github.com/redmine-kit/redmine_aws.git plugins/redmine_kit_aws
git clone https://github.com/redmine-kit/redmine_aws_ssm.git plugins/redmine_kit_aws_ssm
```

プラグインを、パスを指定した gem として `Gemfile.local` に追加し (プラグインの `Gemfile` に書かない理由は [README.md](README.md#when-it-reads))、gem をインストールします。gemspec が必要とする `redmine_kit_aws` も Bundler が見つけられるように、パスで追加します。これは Bundler には読み込ませません (`require: false`。Redmine がプラグインとして読み込みます)。ほかの Redmine Kit AWS のプラグインをパスで追加するときも、`redmine_kit_aws` の行は 1 つだけにします。

```ruby
# Redmine の Gemfile.local
gem 'redmine_kit_aws', path: 'plugins/redmine_kit_aws', require: false
gem 'redmine_kit_aws_ssm', path: 'plugins/redmine_kit_aws_ssm'
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

`bin/test` は、Apple container がインストールされて動いていれば Apple container で、そうでなければ Docker でテストを実行します (`CONTAINER_CLI=container` または `docker` で選べます)。名前空間のテストが読み込む Redmine Kit AWS は、隣のチェックアウト (`../redmine_kit_aws`) か、`REDMINE_KIT_AWS_DIR` のディレクトリから使います。SSM は [AWS Emulator](https://docs.aws.amazon.com/ja_jp/emulator/latest/userguide/) です (`bin/aws_emulator`。Docker では `test/compose.yml`)。AWS のパッケージから、`test/aws-emulator/Dockerfile` で固定したバージョンをインストールし、テレメトリーはオフにします。ログにバージョンを出します。ローダーが呼ぶ SSM の操作 (ページングと復号を使う `GetParametersByPath`、テストの `PutParameter`) はすべてあるので、テストはモックしません。`bin/test` は、先にデフォルトのネットワークで gem をインストールし、そのあと AWS に届かない内部ネットワークでテストを実行します (届くと `test/network_test.rb` が失敗します)。エミュレーターが起動時に書く証明書だけを信頼します (`AWS_CA_BUNDLE`)。証明書には `127.0.0.1` と `localhost` しか含まれないので、テストはエミュレーターにそのアドレスで接続します。Docker ではエミュレーターのネットワーク名前空間で実行します。Apple container は名前空間を共有できないので、`127.0.0.1:9297` をエミュレーターのコンテナに転送します (`test/aws_forward.rb`)。CI は、push のたびに、Ruby 3.2 と 4.0 でテストと静的チェックを実行し、`boot/` のカバレッジ (Ruby 4.0 のもの)を `plugin` フラグで [Codecov](https://codecov.io/gh/redmine-kit/redmine_aws_ssm) に送信します。`COVERAGE=1` を付けると、`bin/test` はローカルでもこのカバレッジを出力します (SimpleCov。Cobertura の XML の `coverage/coverage.xml` と HTML のレポート)。送信の認証は OIDC (`id-token: write`) なので、トークンをシークレットに保存しません。Codecov のステータスは参考情報で、コミットや Pull Request を失敗にしません (`codecov.yml`)。ローカルでは、`TEST_RUBY=3.2 bin/test` (または `bin/lint`) で Ruby 3.2 で実行します。

実行は、終わったときに (テストの成功、失敗、中断のいずれでも)、自分が起動したサービスのコンテナを停止します (削除はしません)。実行の前から動いていたコンテナと、このリポジトリの別の実行がまだ使っているコンテナは、そのまま動かしておきます。`KEEP_SERVICES=1` を指定すると、実行の後も動かしたままにします。

`bin/test-gem` は gem を確認します。チェックアウトからプラグインと Redmine Kit AWS の gem をビルドし、[gem](#gem) のとおりに SQLite の Redmine 7.0.3 にインストールして `plugins/` にリンクし、すべてのファイルを読み込んで Redmine を起動します (`zeitwerk:check` と、起動時にすべてを読み込む production 環境)。`bin/release` もこれを実行するので、gem にないファイルがあれば、リリースで公開する前に失敗します。

```sh
bin/test-gem
```

| テスト | 確認すること |
| --- | --- |
| `test/loader_test.rb` | 10 件を超えるパラメーター (複数のページ)、`SecureString` の復号、設定済みの環境変数、環境変数名にできない名前、下の階層、最後の `/` がないパス、接続できないエンドポイント |
| `test/boot_test.rb` | Redmine と同じ形で定義した Rails 8.1 のアプリケーションを、`REDMINE_SSM_PATH` を設定して別のプロセスで起動する。アプリケーションクラスの本体 (Redmine が `config/additional_environment.rb` を評価するところ) と `config/database.yml` で、Parameter Store の値が環境変数になっていること。パスがなければ何も読み込まないこと。Parameter Store に接続できなければ起動が失敗すること |
| `test/namespace_test.rb` | コードローダーを Redmine 7.0 と同じ形 (プラグインの `lib/` をルートディレクトリにし、イニシャライザーで新しいインフレクタを設定する) にした Rails 8.1 のアプリケーションを、boot ファイルを先に読み込んで別のプロセスで起動する。別のプラグインの `lib/redmine_kit/aws/` のファイルを、コードローダーの既定の名前で読み込めること (`costexplorer.rb` は `RedmineKit::Aws::Costexplorer`)。`RedmineKit::Aws` を先に定義しても、Redmine Kit AWS 自身のファイルを読み込めること。プラグインに `lib/redmine_kit.rb` がないこと |
| `test/network_test.rb` | テストから AWS の SSM と STS に接続できない (`bin/test` のネットワークで) |
| `test/init_test.rb` | Redmine Kit AWS がないとき、`init.rb` が Redmine を停止してその名前を示す (`config/dependencies.rb`)。boot のファイルが実行されていないとき、`Gemfile.local` の行を示す |
| `test/version_test.rb` | gemspec のバージョンがコードのバージョン (`RedmineKit::Aws::Ssm::VERSION`) と同じ |

Serverless も、イメージの中で `test/loader_test.rb` を実行します (`bin/test-image`)。そこでは、3 つの役割が、データベースのホスト、そのパスワード、`SECRET_KEY_BASE` を Parameter Store だけから読み込みます ([Serverless の testing.md](https://redmine-kit.github.io/serverless/ja/testing.html#image-tests))。

<a id="releasing"></a>
## リリース

`bin/release` は、gemspec のバージョンの gem を GitHub Packages の Redmine Kit のレジストリに公開します。実行できるのは変更のない `main` からだけで、バージョンが最後のタグ `v<version>` より新しいこと、必須プラグインがレジストリから範囲どおりに解決できること (`config/dependencies.yml`)、`bin/lint`、`bin/test`、`bin/test-gem` が成功することが条件です。公開には `~/.gem/credentials` のキー `github` (`:github: Bearer <token>`。`write:packages` を持つトークン) を使い、レジストリの読み取りには `BUNDLE_RUBYGEMS__PKG__GITHUB__COM` を使います。トークンはリポジトリにも出力にも含めません。署名付きのタグ `v<version>` を作り、それをプッシュするコマンドを表示します。バージョンはセマンティックバージョニングに従います。このプラグインを使うプラグインが動かなくなる変更ではメジャーバージョン (1.0 より前はマイナーバージョン) を上げ、それを必要とするプラグインの範囲も変えます。

<a id="to-verify"></a>

## 未確認の事項

- デフォルトのキー `aws/ssm` で、IAM が `kms:Decrypt` を許可する必要があるか
