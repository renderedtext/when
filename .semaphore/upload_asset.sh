#!/bin/bash

set -eo pipefail

export REPO_OWNER="renderedtext"
export REPO_NAME="when"
export ASSET_NAME="when_otp_$ERLANG_VERSION"

export RELEASE_ID=$(curl --silent https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/tags/$SEMAPHORE_GIT_TAG_NAME | grep -m1 'id' | awk '{print $2}' | tr -d ',' )

curl -X POST -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Content-Type: $(file -b --mime-type when)" \
  --data-binary @when "https://uploads.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/$RELEASE_ID/assets?name=$ASSET_NAME"
