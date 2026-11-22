# Parameter Store からの設定

Redmine Kit AWS SSM は、データベースのパスワードや `SECRET_KEY_BASE` などの Redmine の設定とシークレットを、Rails の起動前に AWS Systems Manager Parameter Store から環境変数に読み込みます。システム管理者向けのプラグインで、ユーザーから見た違いはなく、Redmine の中にページも設定もありません。

## 読み込む内容

- **1 つのパス**: 環境変数 `REDMINE_SSM_PATH` のパス (例: `/redmine/env/`) の直下にあるパラメータです。この環境変数がなければ、何も読み込みません。`SecureString` パラメータは復号します。
- **名前**: パラメータの名前の最後の部分が環境変数の名前になります。`/redmine/env/SECRET_KEY_BASE` は `SECRET_KEY_BASE` になります。読み込むのは、英大文字、数字、`_` だけの名前です。
- **設定済みの環境変数**は、その値のままです。
- **タイミング**: プロセス (Web サーバー、ジョブ、rake、`rails runner`) の起動時に 1 回読み込みます。パラメータを変更しても、反映されるのは変更後に起動したプロセスだけです。
- **エラー**: Parameter Store を読み込めないとき (経路がない、権限がない) は Redmine を起動しないので、シークレットのないまま動くことはありません。

## ステータスの表示

「管理」›「AWS」›「ステータス」(Redmine Kit AWS) の「Parameter Store」に、Parameter Store から設定した環境変数の名前を表示します。値は表示しません。同じタブの「バージョン」と「管理」›「プラグイン」に、Redmine Kit AWS SSM とそのバージョンを表示します。
