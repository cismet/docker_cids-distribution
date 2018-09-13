#!/bin/bash

CIDS_CTL=${CIDS_DISTRIBUTION_DIR}/utils/cids_ctl.sh

for SERVICE in $(${CIDS_CTL} list_services); do
  ${CIDS_CTL} integrity ${SERVICE} checks_startup
  ${CIDS_CTL} start ${SERVICE}
  ${CIDS_CTL} follow ${SERVICE} &
done

echo -e "\n\e[32mhit [CTRL+C] to exit or run 'docker stop <container>'\e[39m:\n"
trap true SIGTERM
tail -f /dev/null &
wait $!

for SERVICE in $(${CIDS_CTL} list_services); do
  ${CIDS_CTL} stop ${SERVICE}
done