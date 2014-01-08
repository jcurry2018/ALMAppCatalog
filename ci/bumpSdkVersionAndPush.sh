#!/bin/bash

if [ -n "$BUILD_HAS_CHANGES" ]; then
  sed -i "s/appsdk-src:tgz:.*\",/appsdk-src:tgz:${APPSDK_SRC_VERSION}\",/" js_dependencies.json

  git add js_dependencies.json
  git commit -F appsdk.bump --author="${JOB_NAME} <bogus@rallydev.com>"
  git push origin HEAD:$BRANCH

  rm appsdk.bump
else
  exit 1
fi