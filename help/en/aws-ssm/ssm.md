# Settings from Parameter Store

Redmine Kit AWS SSM reads Redmine's settings and secrets, such as the database password and `SECRET_KEY_BASE`, from AWS Systems Manager Parameter Store into environment variables, before Rails starts. It is for system administrators: users see no difference, and the plugin has no page or setting in Redmine.

## What it reads

- **One path**: the parameters directly under the path in the environment variable `REDMINE_SSM_PATH` (for example `/redmine/env/`). Without the variable, nothing is read. `SecureString` parameters are decrypted.
- **Names**: the last part of a parameter's name is the variable's name: `/redmine/env/SECRET_KEY_BASE` becomes `SECRET_KEY_BASE`. Only names made of capital letters, digits and `_` are read.
- **Variables already set** keep their values.
- **When**: once, when a process starts (the web server, jobs, rake, `rails runner`). A changed parameter reaches only the processes started after the change.
- **Errors**: when Parameter Store cannot be read (no route, no permission), Redmine does not start, so it never runs without its secrets.

## Where its status shows

**Parameter Store** on **Administration** › **AWS** › **Status** (Redmine Kit AWS) lists the names of the variables that were set from Parameter Store; the values are never shown. **Versions** on the same tab and **Administration** › **Plugins** list Redmine Kit AWS SSM with its version.
