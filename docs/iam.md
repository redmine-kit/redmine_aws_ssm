# IAM permissions

Every process that starts Rails with the plugin reads the parameters, so each of their roles needs these permissions.

## Permissions

| Action | Resource | Why |
| --- | --- | --- |
| `ssm:GetParametersByPath` | `arn:aws:ssm:<region>:<account>:parameter/<instance>/env` and below it | Reading the parameters under `REDMINE_SSM_PATH`. Also the SSM connection test on Redmine Serverless's "Status" tab |
| `kms:Decrypt` | The key that encrypts the `SecureString` parameters | Decrypting them |

## Example policy

For `REDMINE_SSM_PATH=/<instance>/env/`:

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

## Resource-based policies

None with the default key `aws/ssm`. With a customer managed key, its key policy must also allow the roles to decrypt.

## Not checked yet

- Whether IAM must allow `kms:Decrypt` for `SecureString` parameters encrypted with the default key `aws/ssm`.
