#!/bin/bash

cd ${CIDS_DISTRIBUTION_DIR}/server

export CIDS_STARTER_DIR=${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}
export STARTER_JAR=${SERVICE}-starter.jar
export START_OPTIONS=$*

${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh start

echo -e "\n\e[32mhit [CTRL+C] to exit or run 'docker stop <container>'\e[39m:\n"

tail -f ${SERVICE}.out
