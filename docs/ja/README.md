# Redmine Serverless SSM

Redmine Serverless SSM(`redmine_serverless_ssm`)は、Rails が起動する前に、AWS Systems Manager Parameter Store から設定と秘密の値を環境変数に読み込む Redmine のプラグインです。Redmine を AWS Lambda で動かす [Serverless](https://redmine-kit.github.io/serverless/ja/lambda.html#settings-and-secrets-ssm-parameter-store) が使います。AWS の認証情報がある Redmine なら、コンテナや仮想マシンでも同じように動きます。

<a id="what-it-does"></a>

## すること

- **1 つの道筋を読む:** 環境変数 `REDMINE_SSM_PATH`(例: `/redmine/env/`)があれば、その道筋のすぐ下のパラメーターを `GetParametersByPath` ですべて読みます。1 回の呼び出しの 10 件を超えても続きを読み、`SecureString` は復号します。
- **名前が変数になる:** 名前の最後の部分が変数の名前になります。`/redmine/env/SECRET_KEY_BASE` は `SECRET_KEY_BASE` です。環境変数にできる名前(大文字、数字、`_`)だけを読み、下の階層は読みません。
- **ある変数はそのまま:** すでにある環境変数は上書きしません。手元のテストで、値を直接渡せるようにするためです。
- **早めに失敗する:** Parameter Store につながらなければ、秘密の値なしで起動せずに、Redmine の起動を失敗させます。
- **道筋がなければ何もしない:** `REDMINE_SSM_PATH` がなければ、何も読みません。

<a id="when-it-reads"></a>

## 読む時機

パラメーターは、Rails が `config/database.yml`(データベースのホストとパスワード)と `SECRET_KEY_BASE` を読む前に、環境に入っている必要があります。プラグインの `init.rb` が動くのは、Redmine がコードの準備をするずっとあとなので、読み込みは `init.rb` には置きません。

1. Redmine の `Gemfile.local` で、プラグインを、道筋を指定した gem として足します(`redmine_serverless_ssm.gemspec`)。プラグインの `Gemfile` では足せません。Bundler が、`Gemfile.lock` に道筋をプラグインのディレクトリから見た形で書き、読むときは Redmine のディレクトリから見るためです。
2. `config/application.rb` の `Bundler.require` が、`boot/redmine_serverless_ssm.rb` を読み込みます。
3. アプリのクラスを定義するときに、Railtie の `before_configuration` がパラメーターを読みます。クラスの本体(`config/additional_environment.rb` を含む)より前で、`config/database.yml` を読むより前です。

コードは `lib/` ではなく `boot/` に置きます。Redmine はプラグインの `lib/` を自動の読み込みの対象にしますが、Bundler がもう読み込んだファイルを、自動の読み込みでもう一度読ませないためです。`init.rb` はプラグインの登録だけをして、管理画面の一覧に出します。`RedmineServerlessSsm.loaded` に、読んだ名前を残します(管理画面のため)。

<a id="installation"></a>

## 入れ方

プラグインを `plugins/redmine_serverless_ssm` に置き、Redmine の `Gemfile.local` に次の 1 行を足して、`bundle install` を実行します。

```ruby
gem 'redmine_serverless_ssm', path: 'plugins/redmine_serverless_ssm'
```

`REDMINE_SSM_PATH` を設定し、プロセスに、その道筋への `ssm:GetParametersByPath` を許します(顧客管理のキーで暗号化したパラメーターなら、そのキーへの `kms:Decrypt` も)。

<a id="tests"></a>

## テスト

`test/loader_test.rb` は、SSM の API を再現する moto に対して動きます。Serverless が、イメージの中で実行します(`bin/test-image`)。そこでは、3 つの役割が、データベースのホスト、そのパスワード、`SECRET_KEY_BASE` を Parameter Store だけから読むので、時機も確認できます。
