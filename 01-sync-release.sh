#!/bin/sh

FLATHUB_VERSION=$(curl 'https://release-monitoring.org/api/v2/packages/?name=com.logseq.Logseq&distribution=Flathub'|jq -r '.items[].version')
LATEST_VERSION=$(curl 'https://release-monitoring.org/api/v2/versions/?project_id=291486'|jq -r .latest_version)
FORCE_VERSION=$1

if test -z "$FORCE_VERSION"; then
    VERSION=$LATEST_VERSION
    if test $FLATHUB_VERSION = $VERSION; then
        echo "::set-output name=up_to_date::true"
        echo "Already up to date."
        exit
    fi
else
    VERSION=$FORCE_VERSION
fi


BASE_URL=https://github.com/logseq/logseq/archive/refs/tags

curl -L -o logseq-$VERSION.tar.gz $BASE_URL/$VERSION.tar.gz

tar xf logseq-$VERSION.tar.gz
cd logseq-$VERSION/resources
yarn
cp yarn.lock ../../static/yarn.lock
cd ../..

flatpak-node-generator -r yarn \
  logseq-$VERSION/yarn.lock --electron-node-headers -o generated-sources.json

rm -rf ~/.m2/repository
cd logseq-$VERSION
yarn
yarn gulp:build && yarn cljs:release-electron
cd ..

python3 flatpak-clj-generator-from-cache.py > maven-sources.json