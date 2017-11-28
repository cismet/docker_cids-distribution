#!/bin/bash

cd ${CIDS_DISTRIBUTION_DIR}/server

export STARTER_JAR=${SERVICE}-starter.jar

${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh start

echo -e "\n\e[32mhit [CTRL+C] to exit or run 'docker stop <container>'\e[39m:\n"

while :
do
    # sleep in background in order to make the trap work
    # NOTE: 'read' does not work with docker-compose!
    sleep infinity &

    # wait for last background process (sleep)
    wait $!
    echo -e "\e[33mWARN\e[39m: container stopped with [CTRL+C]"
    exit 0
done
