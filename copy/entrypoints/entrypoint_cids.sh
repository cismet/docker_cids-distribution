#!/bin/bash

cd ${CIDS_DISTRIBUTION_DIR}/server

export STARTER_JAR=${SERVICE}-starter.jar

${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh start

echo -e "\n\e[32mhit [CTRL+C] to exit or run 'docker stop <container>'\e[39m:\n"

tail -f ${SERVICE}.out
