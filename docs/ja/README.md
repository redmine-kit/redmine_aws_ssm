# Redmine AWS SSM

Redmine AWS SSM (`redmine_aws_ssm`) は、Rails が起動する前に、AWS Systems Manager Parameter Store から設定とシークレットを環境変数に読み込む Redmine のプラグインです。[Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#settings-and-secrets-ssm-parameter-store) が Lambda 用のイメージにインストールして使い、AWS の認証情報がある Redmine なら、コンテナや仮想マシンでも同じように動きます。Redmine 本体のファイルは書き換えません。今は開発の初期で、読み込みを実装し、Serverless のイメージでテストしています。

- [導入](setup.md): 動作環境、インストール、設定、AWS リソース、ネットワーク、テスト
- [IAM 権限](iam.md): 権限、ポリシーの例、リソースベースのポリシー

<a id="features"></a>

## 機能

| 機能 | 内容 | 有効にする条件 | 資料 |
| --- | --- | --- | --- |
| Parameter Store の設定 | 1 つのパスの直下のパラメーターを、Rails が `config/database.yml` と `SECRET_KEY_BASE` を読み込む前に、環境変数に読み込む | `REDMINE_SSM_PATH` がある | [setup.md](setup.md#configuration) |
| 管理画面のパラメーター名 | 読み込んだパラメーターの名前 (値ではない) を `RedmineAws::SSM.loaded` に保持する。[Redmine AWS](https://redmine-kit.github.io/redmine_aws/ja/admin.html#status) が「ステータス」のタブに表示する | 同上 | — |

- **1 つのパスを読み込む:** `REDMINE_SSM_PATH` (例: `/redmine/env/`) の直下のパラメーターを、`GetParametersByPath` で読み込みます。1 回の呼び出しの上限の 10 件を超えても続きを読み込み、`SecureString` のパラメーターは復号します。
- **名前が変数名になる:** パラメーター名の最後の部分が変数名になります。`/redmine/env/SECRET_KEY_BASE` は `SECRET_KEY_BASE` です。環境変数名にできる名前 (大文字、数字、`_`) だけを読み込み、下の階層は読み込みません。
- **設定済みの変数は変更しない:** すでにある環境変数は上書きしません。ローカルのテストで値を直接渡せるようにするためです。
- **早めに失敗する:** Parameter Store に接続できなければ、シークレットなしで起動するのではなく、Redmine の起動を失敗させます。

<a id="when-it-reads"></a>

## 読み込みのタイミング

パラメーターは、Rails が `config/database.yml` (データベースのホストとパスワード) と `SECRET_KEY_BASE` を読み込む前に、環境変数になっている必要があります。プラグインの `init.rb` が実行されるのは、Redmine がコードを準備するずっとあとなので、読み込みは `init.rb` には置きません。

1. Redmine の `Gemfile.local` で、プラグインをパスを指定した gem として追加します (`redmine_aws_ssm.gemspec`)。プラグインの `Gemfile` では追加できません。Bundler は、`Gemfile.lock` にパスをプラグインのディレクトリからの相対パスで書き、読み込むときは Redmine のディレクトリからの相対パスとして扱うからです。
2. `config/application.rb` の `Bundler.require` が、`boot/redmine_aws_ssm.rb` を読み込みます。
3. アプリケーションクラスを定義するときに、Railtie の `before_configuration` がパラメーターを読み込みます。クラスの本体 (`config/additional_environment.rb` を含む) より前で、`config/database.yml` を読み込むより前です。

コードは `lib/` ではなく `boot/` に置きます。Redmine はプラグインの `lib/` を自動読み込みの対象にしますが、Bundler が読み込み済みのファイルを、自動読み込みでもう一度読み込ませないためです。`init.rb` はプラグインを登録するだけで、これにより管理画面のプラグイン一覧に表示されます。ほかの Redmine AWS のプラグインと同じく、[Redmine AWS](https://redmine-kit.github.io/redmine_aws/ja/) を必要とします (`init.rb` の `requires_redmine_plugin` と、gem の依存関係)。ただし、読み込みはそのコードを使いません。Redmine がそのプラグインのコードを読み込むのは、パラメーターを読み込んだあとだからです。`Bundler.require` は Gemfile にある gem だけを読み込み、その依存関係は読み込まないので、Bundler が `redmine_aws` を早く読み込むことはありません。コードは Redmine AWS のプラグインの名前空間 `RedmineAws` の下の `RedmineAws::SSM` にあるので、`boot/` は、Redmine AWS が定義するより前にモジュール `RedmineAws` を開きます。そのため Redmine AWS は、`lib/redmine_aws.rb` を Redmine の自動読み込みに任せず、自身の `init.rb` から読み込みます。その前に `boot/` は、Redmine AWS が登録する活用形 (`redmine_aws/inflections`。`ses` → `SES` など) を読み込みます。`RedmineAws` が早く定義されていると、Rails のコードローダーは、セットアップの時点で、どの `init.rb` よりも前に、ほかのプラグインの `lib/redmine_aws/` の下のファイルの定数名を決めるからです。

<a id="each-process"></a>

## プロセス別の読み込み

Rails の環境を読み込むプロセスは、どれも起動時に 1 回だけパラメーターを読み込みます。Web サーバー、バックグラウンドジョブ、`rake`、`rails runner` です。そのため、変更した値は、変更後に起動したプロセスにだけ反映されます。Lambda では、関数の設定を更新したあとなどに作成される、新しい実行環境がこれに当たります。

データベースのホストとパスワードが Parameter Store から来ても、データベースの gem は正しく選ばれます。Redmine の `Gemfile` は、`config/database.yml` を評価せず、`adapter:` に書かれた文字列から gem を選ぶからです。

Parameter Store がエラーを返したとき (経路がない、権限がない) は、プラグインが例外を発生させ、Rails が設定を読み込む前にプロセスが停止します。値の一部だけで Redmine が動くことはありません。

<a id="sponsors"></a>

## スポンサー

<Sponsors><a href="https://www.keyselect.co.jp/">KEY SELECT</a> <a href="https://localstack.cloud">LocalStack</a></Sponsors>

<a id="license"></a>

## ライセンス

Redmine AWS SSM は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](../../LICENSE) を参照してください。Redmine の非公式のプラグインです。
