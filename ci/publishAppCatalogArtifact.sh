#!/bin/bash -el

npm install
grunt nexus:deploy
grunt nexus:verify
grunt writeVersion
echo -e "APP_CATALOG_SRC_VERSION=$(cat appcatalog.version)" > appcatalog.version
grunt npm:publish
