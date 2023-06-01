#!/bin/bash

MODE=${CIDS_CTL_MODE:-multi}

if [ ! -z "${EXEC_BEFORE_START}" ]; then
  echo -e "\e[32mINFO\e[39m: executing ${EXEC_BEFORE_START}"
  bash -c "${EXEC_BEFORE_START}" || exit 1;
fi

if [ "${MODE}" == "single" ]; then
  CIDS_CTL=${CIDS_DISTRIBUTION_DIR}/utils/cids_ctl_single.sh
 else
  CIDS_CTL=${CIDS_DISTRIBUTION_DIR}/utils/cids_ctl.sh
fi

if [ "${MODE}" == "single" ]; then
  ${CIDS_CTL} pull
  ${CIDS_CTL} prepare
  ${CIDS_CTL} integrity checks_startup
  ${CIDS_CTL} start
  ${CIDS_CTL} follow &
else
  for SERVICE in $(${CIDS_CTL} list_services); do
    ${CIDS_CTL} integrity ${SERVICE} checks_startup
    ${CIDS_CTL} start ${SERVICE}
    ${CIDS_CTL} follow ${SERVICE} &
  done
fi

echo -e "\n\e[32mhit [CTRL+C] to exit or run 'docker stop <container>'\e[39m:\n"
trap true SIGTERM
tail -f /dev/null &
wait $!

if [ "${MODE}" == "single" ]; then
  ${CIDS_CTL} stop
else
  for SERVICE in $(${CIDS_CTL} list_services); do
    ${CIDS_CTL} stop ${SERVICE}
  done
fi