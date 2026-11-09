# AGENTS.md

Guidelines for people and coding agents working in this repository. See [README.md](README.md) for an overview and [docs/](docs/README.md) for the design.

## What this project does

Redmine Serverless SSM (`redmine_serverless_ssm`) is a Redmine plugin that reads settings and secrets from AWS Systems Manager Parameter Store into environment variables before Rails starts. It works with or without AWS Lambda. [Serverless](https://github.com/redmine-kit/serverless) installs it with the other Redmine Serverless plugins. It is in early development.

## Rules

- **Before the configuration:** the reading must stay in `boot/` and run from the Railtie's `before_configuration`, before `config/database.yml` and `SECRET_KEY_BASE` are read ([docs/README.md](docs/README.md#when-it-reads)). Do not move it to `init.rb` or `lib/`.
- **Off without its setting:** without `REDMINE_SSM_PATH`, nothing is read.
- **Never print values:** log and keep only names, never parameter values.
- **Tests:** `test/loader_test.rb` runs against moto inside the Serverless image (`bin/test-image` of Serverless, with `REDMINE_SERVERLESS_SSM_DIR` pointing at this checkout).
- **No secrets in the repository.**

## Documentation

- **Two languages.** English is the source (`README.md`, `docs/`); the Japanese translation is `README.ja.md` and `docs/ja/`, with the same file names. Change both together.
- **Layout.** The READMEs stay short. The details go in `docs/`, published at https://redmine-kit.github.io/redmine_serverless_ssm/ with [redmine-kit/docs-skeleton](https://github.com/redmine-kit/docs-skeleton). `docs/README.md` has the overview and the features, `docs/setup.md` the sections Requirements, Installation, Configuration, AWS resources, IAM permissions, Network, Tests and To verify, in this order (the same in every Redmine Serverless plugin; IAM permissions there is one line that points to `docs/iam.md`), `docs/iam.md` the sections Permissions, Example policy, Resource-based policies and Not checked yet. Links to the documentation of Serverless and the other plugins are absolute URLs.
- **Anchors in Japanese.** Put `<a id="..."></a>` with the English heading's anchor before each Japanese heading.
- **Facts.** State only what has been checked, with the date and the source. Mark what has not been checked yet.
- **Japanese wording.** Plain, precise Japanese. Keep established technical terms. Do not use "版" for a version, write "通知" rather than "知らせ", "確認" rather than "確かめ", and "インストール" rather than "入れ方".

## Commits

- English, imperative mood, 72 characters or fewer in the first line, no trailing period.
- One purpose per commit.
- Do not rewrite pushed history.
