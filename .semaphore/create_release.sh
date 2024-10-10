#!/bin/bash

set -eo pipefail

export REPO_OWNER="renderedtext"
export REPO_NAME="when"

curl \
  -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases \
  -d '{"tag_name":"'$SEMAPHORE_GIT_TAG_NAME'"}'
