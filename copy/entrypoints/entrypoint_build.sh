#!/bin/bash

GIT_DISTRIBUTION_RELEASE=$1

AUTO_DISTRIBUTION_DIR=${CIDS_GENERATOR_DIR}/cids-auto-distribution

if [ ! -z "${GIT_DISTRIBUTION_RELEASE}" ]; then
  GIT_DISTRIBUTION_DOWNLOAD_URL=https://github.com/${GIT_DISTRIBUTION_PROJECT}/archive/v${GIT_DISTRIBUTION_RELEASE}.tar.gz
  mkdir ${AUTO_DISTRIBUTION_DIR}
  echo "downloading distribution from: ${GIT_DISTRIBUTION_DOWNLOAD_URL} ..."
  curl -fsSL ${GIT_DISTRIBUTION_DOWNLOAD_URL} | tar -xz -C ${AUTO_DISTRIBUTION_DIR} --strip-components=1
fi

cd "${CIDS_DISTRIBUTION_DIR}/scripts/before-build/" && \
for SCRIPT in $(ls -1 | grep -E "^[0-9]{3}_.*$" | sort); do
  echo "executing before-build script $SCRIPT ..."
  source $SCRIPT;
done && cd -

CIDS_LOCAL_DIR=${CIDS_LIB_DIR}/local${CIDS_ACCOUNT_EXTENSION}
CIDS_STARTER_DIR=${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}
if [ -z ${MAVEN_BUID_COMMAND} ];  then
  MAVEN_BUID_COMMAND="clean install"
fi

echo "building distribution..."
source ${CIDS_DISTRIBUTION_DIR}/utils/_build_autodistribution.master.sh

if [ 1 -eq "$SIGN_INT" ]; then
  echo "signing all int jars..."
  ${CIDS_DISTRIBUTION_DIR}/utils/sign_all.sh ${CIDS_DISTRIBUTION_DIR}/lib/int
fi && cd -

cd "${CIDS_DISTRIBUTION_DIR}/scripts/after-build/" && \
for SCRIPT in $(ls -1 | grep -E "^[0-9]{3}_.*$" | sort); do
  echo "executing after-build script $SCRIPT ..."
  source $SCRIPT;
done

if [ ! -z "${GIT_DISTRIBUTION_RELEASE}" ]; then
  rm -rf ${AUTO_DISTRIBUTION_DIR}
fi