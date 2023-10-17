#!/bin/bash

LOGIN_NAME=$1
PASSWORD=$2
OLD_PASSWORD=$3
TIMESTAMP=$4

CSCONF_BIN=${CSCONF_BIN:=/cidsDistribution/utils/csconf}

echo "changing password for '${LOGIN_NAME}'"

if [ "${PASSWORD}" == "${OLD_PASSWORD}" ]; then
  echo "old and new password is identical" > /dev/stderr
  exit 1
fi

### preventing that files change by another process while importing
CSCONF_IMPORT_DIR="/tmp/csconf-import_$(echo $RANDOM | md5sum | head -c 20)";

cp -r "${GIT_TARGET_csconf}" "${CSCONF_IMPORT_DIR}"
cd "${CSCONF_IMPORT_DIR}"

git reset --hard HEAD
git checkout "${GIT_BRANCH}"
git pull origin "${GIT_BRANCH}"

OLD_USER=$(cat usermanagement.json | jq '.[] | select(.login_name == "'${LOGIN_NAME}'")')
OLD_HASH=$(echo ${OLD_USER} | jq -r '.pw_hash')
OLD_SALT=$(echo ${OLD_USER} | jq -r '.salt')

TST_USER=$(${CSCONF_BIN} password -u "${LOGIN_NAME}" -p "${OLD_PASSWORD}" -s "${OLD_SALT}" -Pq)
TST_HASH=$(echo ${TST_USER} | jq -r '.pw_hash')

if [ "${TST_HASH}" != "${OLD_HASH}" ]; then
  echo "old and new password hashes don't match" > /dev/stderr
  exit 1
fi

TIME=$(date -d "@$((${TIMESTAMP} / 1000))" "+%d.%m.%Y, %H:%M:%S")

NEW_USER=$(${CSCONF_BIN} password -u "${LOGIN_NAME}" -p "${PASSWORD}" -t "${TIME}" -q)

echo "${NEW_USER}" | jq '{ "login_name": .login_name, "pw_hash": .pw_hash, "salt": .salt, "last_pwd_change": .last_pwd_change }'

COMMIT_MSG="[no-import] user ${LOGIN_NAME} changed own password"
git add usermanagement.json

git config --global user.email "cids-live@s10222.wuppertal-intra.de"
git config --global user.name "cids-live"

git commit -m "${COMMIT_MSG}"

git push -u origin "${GIT_BRANCH}"

cd -
rm -r "${CSCONF_IMPORT_DIR}"