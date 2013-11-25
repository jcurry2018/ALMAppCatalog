#!/bin/bash

sed -i "s/appsdk-src:tgz:.*\",/appsdk-src:tgz:${APPSDK_SRC_VERSION}\",/" js_dependencies.json

git add js_dependencies.json
git commit -F appsdk.bump --author="${JOB_NAME} <bogus@rallydev.com>"
git push origin HEAD:master

rm appsdk.bump