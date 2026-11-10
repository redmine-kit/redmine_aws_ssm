# Redmine Serverless SSM

Redmine Serverless SSM(`redmine_serverless_ssm`)は、Rails が起動する前に、AWS Systems Manager Parameter Store から設定と秘密の値を環境変数に読み込む Redmine のプラグインです。[Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#settings-and-secrets-ssm-parameter-store) が Lambda 用のイメージに入れて使い、AWS の認証情報がある Redmine なら、コンテナや仮想マシンでも同じように動きます。Redmine 本体のファイルは書き換えません。今は開発の初期で、読み込みを実装し、Serverless のイメージでテストしています。

- [導入](setup.md): 動作環境、インストール、設定、AWS リソース、ネットワーク、テスト
- [IAM 権限](iam.md): 権限、ポリシーの例、リソースベースのポリシー

<a id="features"></a>

## 機能

| 機能 | 内容 | 有効にする条件 | 資料 |
| --- | --- | --- | --- |
| Parameter Store の設定 | 1 つのパスのすぐ下のパラメーターを、Rails が `config/database.yml` と `SECRET_KEY_BASE` を読む前に、環境変数に読み込む | `REDMINE_SSM_PATH` がある | [setup.md](setup.md#configuration) |
| 管理画面の名前 | 読んだ名前(値ではない)を `RedmineServerlessSsm.loaded` に残す。[Redmine Serverless](https://redmine-kit.github.io/redmine_serverless/ja/admin.html#status-and-connections) が「ステータス」のタブに出す | 同上 | — |

- **1 つのパスを読む:** `REDMINE_SSM_PATH`(例: `/redmine/env/`)のすぐ下のパラメーターを、`GetParametersByPath` で読みます。1 回の呼び出しの 10 件を超えても続きを読み、`SecureString` は復号します。
- **名前が変数になる:** 名前の最後の部分が変数の名前になります。`/redmine/env/SECRET_KEY_BASE` は `SECRET_KEY_BASE` です。環境変数にできる名前(大文字、数字、`_`)だけを読み、下の階層は読みません。
- **ある変数はそのまま:** すでにある環境変数は上書きしません。手元のテストで、値を直接渡せるようにするためです。
- **早めに失敗する:** Parameter Store につながらなければ、秘密の値なしで起動せずに、Redmine の起動を失敗させます。

<a id="when-it-reads"></a>

## 読み込みのタイミング

パラメーターは、Rails が `config/database.yml`(データベースのホストとパスワード)と `SECRET_KEY_BASE` を読む前に、環境に入っている必要があります。プラグインの `init.rb` が動くのは、Redmine がコードの準備をするずっとあとなので、読み込みは `init.rb` には置きません。

1. Redmine の `Gemfile.local` で、プラグインを、パスを指定した gem として追加します(`redmine_serverless_ssm.gemspec`)。プラグインの `Gemfile` では追加できません。Bundler が、`Gemfile.lock` にパスをプラグインのディレクトリから見た形で書き、読むときは Redmine のディレクトリから見るためです。
2. `config/application.rb` の `Bundler.require` が、`boot/redmine_serverless_ssm.rb` を読み込みます。
3. アプリのクラスを定義するときに、Railtie の `before_configuration` がパラメーターを読みます。クラスの本体(`config/additional_environment.rb` を含む)より前で、`config/database.yml` を読むより前です。

コードは `lib/` ではなく `boot/` に置きます。Redmine はプラグインの `lib/` を自動の読み込みの対象にしますが、Bundler がもう読み込んだファイルを、自動の読み込みでもう一度読ませないためです。`init.rb` はプラグインの登録だけをして、管理画面の一覧に出します。

<a id="each-process"></a>

## プロセス別の読み込み

Rails の環境を読み込むプロセスは、どれも起動のときに 1 回だけパラメーターを読みます。Web のサーバー、バックグラウンドのジョブ、`rake`、`rails runner` です。そのため、変えた値は、変えたあとに起動したプロセスにだけ届きます。Lambda では、関数の設定を更新したあとなどにできる、新しい実行環境がこれに当たります。

ホストとパスワードが Parameter Store から来ても、データベースの gem は正しく選ばれます。Redmine の `Gemfile` は、`config/database.yml` を評価せず、`adapter:` に書いた文字列を見て gem を選ぶからです。

Parameter Store がエラーを返したとき(経路がない、権限がない)は、プラグインが例外を発生させ、Rails が設定を読む前にプロセスが止まります。値の一部だけで Redmine が動くことはありません。

<a id="sponsors"></a>

## スポンサー

<Sponsors><a href="https://www.keyselect.co.jp/">KEY SELECT</a> <a href="https://localstack.cloud">LocalStack</a></Sponsors>

<a id="license"></a>

## ライセンス

Redmine Serverless SSM は、GNU General Public License バージョン 2 またはそれ以降のバージョンで公開しています。[LICENSE](../../LICENSE) を参照してください。Redmine の非公式のプラグインです。
