#!/bin/bash -el

sed -i "s/appsdk-src:tgz:[^\"]*\",/appsdk-src:tgz:${APPSDK_SRC_VERSION}\",/" js_dependencies.json

git add js_dependencies.json
git config user.name Hudson
git config user.email hudson@rallydev.com
git commit -F appsdk.bump --author="${JOB_NAME} <bogus@rallydev.com>"

branch_name_only=`echo $GIT_BRANCH | sed -e "s/origin\///g"`

if [ "$SHOULD_PUSH" == "true" ]; then
    git push origin HEAD:$branch_name_only
else
    echo "NOT COMMITING!!"
    git reset --hard
fi

rm appsdk.bump
