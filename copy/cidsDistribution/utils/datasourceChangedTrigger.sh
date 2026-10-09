#!/bin/bash

echo "refresh data source capabilities"

### preventing that files change by another process while importing
SERVER_RES_IMPORT_DIR="/tmp/server-res-import_$(echo $RANDOM | md5sum | head -c 20)";

cp -r "${GIT_TARGET_resources}" "${SERVER_RES_IMPORT_DIR}"
cd "${SERVER_RES_IMPORT_DIR}"

git checkout "${GIT_BRANCH}"
git pull origin "${GIT_BRANCH}"


COMMIT_MSG="[no-import] data source capabilities was refreshed"
git add datasources/capabilities.xml

git config --global user.email "cids-live@sl0548.wuppertal-intra.de"
git config --global user.name "cids-live"

git commit -m "${COMMIT_MSG}"

git push -u origin "${GIT_BRANCH}"

cd -
rm -r "${SERVER_RES_IMPORT_DIR}"