# IAM 権限

プラグインをインストールして Rails を起動するプロセスは、どれもパラメーターを読み込むので、そのすべてのロールにこの権限が必要です。

<a id="permissions"></a>

## 権限

| アクション | リソース | 理由 |
| --- | --- | --- |
| `ssm:GetParametersByPath` | `arn:aws:ssm:<region>:<account>:parameter/<instance>/env` と、その下 | `REDMINE_SSM_PATH` の下のパラメーターを読み込む |
| `kms:Decrypt` | `SecureString` のパラメーターを暗号化したキー | 復号する |

<a id="example-policy"></a>

## ポリシーの例

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

## リソースベースのポリシー

デフォルトのキー `aws/ssm` なら、ありません。カスタマーマネージドキーなら、そのキーポリシーでも、ロールに復号を許可します。

<a id="not-checked-yet"></a>

## 未確認の事項

- デフォルトのキー `aws/ssm` で暗号化した `SecureString` のパラメーターに、IAM で `kms:Decrypt` を許可する必要があるか。
