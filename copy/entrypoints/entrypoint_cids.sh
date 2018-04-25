#!/bin/bash

export CIDS_STARTER_DIR=${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}
export START_OPTIONS=$*

serversPath=${CIDS_DISTRIBUTION_DIR}/server
cd $serversPath
for serverDir in $(ls -1 . | grep -E "^[0-9]{3}_.*$" | sort); do
  export SERVICE_DIR=$serversPath/$serverDir
  export SERVICE=${serverDir:4}
  export STARTER_JAR=${SERVICE}-starter.jar
  export SLEEP_BEFORE_START=1

  ENV_FILE=$serverDir/ENV
  if [ -f ${ENV_FILE} ]; then
    source ${ENV_FILE}
  fi

  sleep ${SLEEP_BEFORE_START}
  ${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh start
  tail -f ${SERVICE_DIR}/$SERVICE.out &
done

echo -e "\n\e[32mhit [CTRL+C] to exit or run 'docker stop <container>'\e[39m:\n"
trap true SIGTERM
tail -f /dev/null &
wait $!

for serverDir in $(ls -1 . | grep -E "^[0-9]{3}_.*$" | sort -r); do
  export SERVICE_DIR=$serversPath/$serverDir
  export SERVICE=${serverDir:4}
  export SLEEP_BEFORE_STOP=1

  ENV_FILE=$serverDir/ENV
  if [ -f ${ENV_FILE} ]; then
    source ${ENV_FILE}
  fi

  sleep ${SLEEP_BEFORE_STOP}
  ${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh stop
done
