# IAM 権限

プラグインを入れて Rails を起動するプロセスは、どれもパラメーターを読むので、そのすべてのロールにこの権限が要ります。

<a id="permissions"></a>

## 権限

| 操作 | 対象 | 理由 |
| --- | --- | --- |
| `ssm:GetParametersByPath` | `arn:aws:ssm:<region>:<account>:parameter/<instance>/env` と、その下 | `REDMINE_SSM_PATH` の下のパラメーターを読む。Redmine Serverless の「ステータス」のタブの SSM の接続テストにも使う |
| `kms:Decrypt` | `SecureString` のパラメーターを暗号化した鍵 | 復号する |

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

既定の鍵 `aws/ssm` なら、ありません。顧客管理の鍵なら、その鍵のポリシーでも、ロールに復号を許します。

<a id="not-checked-yet"></a>

## 未確認の事項

- 既定の鍵 `aws/ssm` で暗号化した `SecureString` のパラメーターに、IAM で `kms:Decrypt` を許す必要があるか。
