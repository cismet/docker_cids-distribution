#!/bin/bash

for EXEC_CI_DIR in ${EXEC_CI_DIRS}; do
    cd "${EXEC_CI_DIR}" || exit 4
    if [ -f .gitlab-ci.yml ]; then
        for JOB in $(grep "\-job" .gitlab-ci.yml); do
            echo -e "\e[32mINFO\e[39m: executing ci job ${JOB} in ${EXEC_CI_DIR}"
            gitlab-runner exec shell "${JOB%%:}" || exit 5
        done
    fi
done