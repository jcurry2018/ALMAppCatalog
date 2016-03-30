#!/bin/bash -el

npm install

if [ ! -z "$APPSDK_SRC_VERSION" ]; then
    npm install rally-appsdk@${APPSDK_SRC_VERSION} --save --save-exact
fi

grunt build

# grunt clean nexus:deploy
# 1) ^ this goes away
# 2) add the SHORT_JOB_NAME to the job
# 3) we add the following v
grunt bump-only:patch

bump_version=`npm ll --depth=0 rally-app-catalog | grep rally-app-catalog | awk -F'@' '{print $2}'`
npm_version="${bump_version}-${SHORT_JOB_NAME}-${ARTIFACT_VERSION}"

grunt bump-only --setversion=${npm_version}
echo "Npm tag: ${ARTIFACT_PREFIX}-${ARTIFACT_VERSION}"
npm publish
npm dist-tag add rally-app-catalog@${npm_version} "${ARTIFACT_PREFIX}-${ARTIFACT_VERSION}"
