#!/bin/bash

GIT_DISTRIBUTION_RELEASE=$1

if [ -z "${GIT_DISTRIBUTION_RELEASE}" ]; then
  GIT_DISTRIBUTION_DOWNLOAD_URL=https://codeload.github.com/${GIT_DISTRIBUTION_PROJECT}/tar.gz/dev
else
  GIT_DISTRIBUTION_DOWNLOAD_URL=https://github.com/${GIT_DISTRIBUTION_PROJECT}/archive/v${GIT_DISTRIBUTION_RELEASE}.tar.gz
fi

AUTO_DISTRIBUTION_DIR=${CIDS_GENERATOR_DIR}/cids-auto-distribution

# ---
mkdir ${AUTO_DISTRIBUTION_DIR}
echo "downloading distribution from: ${GIT_DISTRIBUTION_DOWNLOAD_URL} ..."
curl -fsSL ${GIT_DISTRIBUTION_DOWNLOAD_URL} | tar -xz -C ${AUTO_DISTRIBUTION_DIR} --strip-components=1
CIDS_LOCAL_DIR=${CIDS_LIB_DIR}/local${CIDS_ACCOUNT_EXTENSION}
CIDS_STARTER_DIR=${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}
MAVEN_BUID_COMMAND="clean install"
source ${CIDS_DISTRIBUTION_DIR}/utils/_build_autodistribution.master.sh

rm -rf ${AUTO_DISTRIBUTION_DIR}
