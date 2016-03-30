#!/bin/bash -el

npm install
grunt nexus:deploy
grunt nexus:verify
grunt writeVersion
echo -e "APP_CATALOG_SRC_VERSION=$(cat appcatalog.version)" > appcatalog.version
grunt npm:publish

echo "Npm tag: ${ARTIFACT_PREFIX}-${ARTIFACT_VERSION}"
bump_version=`npm ll --depth=0 rally-app-catalog | grep rally-app-catalog | awk -F'@' '{print $2}'`
npm dist-tag add rally-app-catalog@${bump_version} "${ARTIFACT_PREFIX}-${ARTIFACT_VERSION}"
