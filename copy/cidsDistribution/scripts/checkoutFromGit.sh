#!/bin/bash

for GIT_DIR in ${GIT_DIRS}; do
    echo -e "\e[32mINFO\e[39m: pulling for ${GIT_DIR}"
    cd "${GIT_DIR}" || exit 1
    git pull || exit 2

    if [ ! -z "${CIDSDISTRIBUTION_FLAVOR}" ]; then
        echo -e "\e[32mINFO\e[39m: checking out into ${CIDSDISTRIBUTION_FLAVOR}"
        git checkout "${CIDSDISTRIBUTION_FLAVOR}" || exit 3
    fi    
done