#!/bin/bash -el

npm install

if [ ! -z "$APPSDK_SRC_VERSION" ]; then
    npm install rally-appsdk@${APPSDK_SRC_VERSION}
fi

grunt clean nexus:deploy
