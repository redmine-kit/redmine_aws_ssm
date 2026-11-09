# 準備

Redmine Serverless SSM を使う Redmine に要るもの(インストール、設定、前提にする AWS のリソース、IAM の権限、ネットワーク)です。[Serverless](https://redmine-kit.github.io/serverless/ja/) は、これらをすべて CloudFormation で作ります。このページは、手で用意するときや、Serverless が作るものを確認するときのためのものです。

<a id="requirements"></a>

## 前提

- Ruby 4.0 以降の上の Redmine 7.0 以降。
- SSM を呼べる AWS の認証情報を持つプロセス(Lambda では実行ロール、ほかではインスタンスプロファイルやタスクのロール)。

<a id="installation"></a>

## インストール

1. プラグインを `plugins/redmine_serverless_ssm` に置きます。
2. Redmine の `Gemfile.local` に次の 1 行を足して、`bundle install` を実行します(この行をプラグインの `Gemfile` に置かない理由は [README.md](README.md#when-it-reads) にあります)。

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

プラグインを入れて Rails を起動するプロセスは、どれもパラメーターを読むので、そのすべてのロールにこの権限が要ります。

| 操作 | 対象 | 理由 |
| --- | --- | --- |
| `ssm:GetParametersByPath` | `arn:aws:ssm:<region>:<account>:parameter/<instance>/env` と、その下 | `REDMINE_SSM_PATH` の下のパラメーターを読む。Redmine Serverless の「状態と接続」の SSM の確認にも使う |
| `kms:Decrypt` | `SecureString` のパラメーターを暗号化した鍵 | 復号する |

<a id="example-policy"></a>

### 例のポリシー

`REDMINE_SSM_PATH=/<instance>/env/` のときです。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSettings",
      "Effect": "Allow",
      "Action": "ssm:GetParametersByPath",
      "Resource": [
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env",
        "arn:aws:ssm:<region>:<account>:parameter/<instance>/env/*"
      ]
    },
    {
      "Sid": "DecryptSettings",
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "*",
      "Condition": { "StringEquals": { "kms:ViaService": "ssm.<region>.amazonaws.com" } }
    }
  ]
}
```

<a id="resource-based-policies"></a>

### リソースベースのポリシー

既定の鍵 `aws/ssm` なら、ありません。顧客管理の鍵なら、その鍵のポリシーでも、ロールに復号を許します。

<a id="not-checked-yet"></a>

### 未確認のこと

- 既定の鍵 `aws/ssm` で暗号化した `SecureString` のパラメーターに、IAM で `kms:Decrypt` を許す必要があるか。

<a id="network"></a>

## ネットワーク

| 行き先 | API | インターネットに出られない VPC の中では |
| --- | --- | --- |
| SSM | `GetParametersByPath` | インターフェースのエンドポイント `com.amazonaws.<region>.ssm` |

呼び出しは、プロセスが起動するときに 1 回です。エンドポイントに届かなければ、起動が失敗します。

<a id="tests"></a>

## テスト

`test/loader_test.rb` は、SSM の API を再現する moto に対して動きます。Serverless が、イメージの中で実行します(`bin/test-image`)。そこでは、3 つの役割が、データベースのホスト、そのパスワード、`SECRET_KEY_BASE` を Parameter Store だけから読むので、時機も確認できます。

<a id="to-verify"></a>

## 確認すること

- 既定の鍵 `aws/ssm` で、IAM が `kms:Decrypt` を許す必要があるか
