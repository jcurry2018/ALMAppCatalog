#!/bin/bash -e

rm -rf bin/sencha lib/ext/4.2.2 lib/webdriver

mkdir -p lib/ext bin/
cp -rp node_modules/rally-ext-lean lib/ext/4.2.2
rm -f lib/ext/4.2.2/package.json

cp -rp node_modules/rally-sencha-cmd bin/sencha
cp -rp node_modules/rally-webdriver lib/webdriver
