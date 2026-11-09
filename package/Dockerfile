# syntax=docker/dockerfile:1
# The plugin's run-time files as an image at /redmine_serverless_ssm, published to
# ghcr.io/redmine-kit/redmine_serverless_ssm (.github/workflows/package.yml). A Redmine image
# takes them with:
#   COPY --from=ghcr.io/redmine-kit/redmine_serverless_ssm:<tag>@sha256:<digest> /redmine_serverless_ssm plugins/redmine_serverless_ssm/
# .dockerignore chooses the files; those that do not exist yet are left out.
# Built from the repository root: docker build -f package/Dockerfile .
FROM scratch
LABEL org.opencontainers.image.source=https://github.com/redmine-kit/redmine_serverless_ssm \
  org.opencontainers.image.description="The Redmine plugin redmine_serverless_ssm: run-time files" \
  org.opencontainers.image.licenses=GPL-2.0-or-later
COPY . /redmine_serverless_ssm/
