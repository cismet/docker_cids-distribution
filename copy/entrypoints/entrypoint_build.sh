#!/bin/bash

GIT_BRANCH=$1

if [ -z "${GIT_BRANCH}" ]; then
  GIT_BRANCH=dev
fi

echo ${AUTO_DISTRIBUTION_DOWNLOAD_URL_BASE}/${GIT_BRANCH}
DOWNLOAD_URL=${AUTO_DISTRIBUTION_DOWNLOAD_URL_BASE}/${GIT_BRANCH}
AUTO_DISTRIBUTION_DIR=${CIDS_GENERATOR_DIR}/cids-auto-distribution
MAVEN_BUID_COMMAND="clean install"

# ---

mkdir ${AUTO_DISTRIBUTION_DIR}
curl -fsSL ${DOWNLOAD_URL} | tar -xz -C ${AUTO_DISTRIBUTION_DIR} --strip-components=1
source ${CIDS_DISTRIBUTION_DIR}/utils/_build_autodistribution.master.sh
rm -rf ${AUTO_DISTRIBUTION_DIR}
