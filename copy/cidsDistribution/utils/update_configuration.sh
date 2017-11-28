#!/bin/bash

DOCKER_HOST_IP=$(ip route|awk '/default/ { print $3 }')
pattern='^[0-9]{3}_.+$'
cd $CIDS_SERVER_DIR
for SERVICE_DIR in *; do
    if [[ -d $SERVICE_DIR && $SERVICE_DIR =~ $pattern ]]; then
        if grep -q __DOCKER_HOST__ "${SERVICE_DIR}/runtime.properties" ; then
            echo -e "\e[32mINFO\e[39m: Updating ${SERVICE_DIR}/runtime.properties docker host ip with ${DOCKER_HOST_IP}"
            sed -i -- "s/__DOCKER_HOST__/${DOCKER_HOST_IP}/g" ${SERVICE_DIR}/runtime.properties 2>> /dev/null
        fi

        if grep -q __DOCKER_HOST__ "${SERVICE_DIR}/log4j.properties" || grep -q __DOCKER_HOST__ "${SERVICE_DIR}/log4j.properties" ; then
            echo -e "\e[32mINFO\e[39m: Updating ${CIDS_SERVER_DIR}/log4j.properties remote LOG4J host with ${DOCKER_HOST_IP}:${LOG4J_PORT:-4445}"
            sed -i -- "s/__DOCKER_HOST__/${DOCKER_HOST_IP}/g" ${SERVICE_DIR}/log4j.properties 2>> /dev/null
            sed -i -- "s/__DOCKER_HOST__/${LOG4J_PORT:-4445}/g" ${SERVICE_DIR}/log4j.properties 2>> /dev/null
        fi

        if grep -q __DB_HOST__ "${SERVICE_DIR}/runtime.properties" || grep -q __DB_PORT__ "${SERVICE_DIR}/runtime.properties" ; then
            echo -e "\e[32mINFO\e[39m: Updating ${SERVICE_DIR}/runtime.properties JDBC Connection with ${CIDS_INTEGRATION_BASE_PORT_5432_TCP_ADDR:-$DOCKER_HOST_IP}:${CIDS_INTEGRATION_BASE_PORT_5432_TCP_PORT:-5432}"
            sed -i -- "s/__DB_HOST__/${CIDS_INTEGRATION_BASE_PORT_5432_TCP_ADDR:-$DOCKER_HOST_IP}/g" ${SERVICE_DIR}/runtime.properties 2>> /dev/null
            sed -i -- "s/__DB_PORT__/${CIDS_INTEGRATION_BASE_PORT_5432_TCP_PORT:-5432}/g" ${SERVICE_DIR}/runtime.properties 2>> /dev/null
        fi

        if grep -q __LOG4J_HOST__ "${SERVICE_DIR}/runtime.properties" || grep -q __LOG4J_PORT__ "${SERVICE_DIR}/runtime.properties" ; then
            echo -e "\e[32mINFO\e[39m: Updating ${CIDS_SERVER_DIR}/runtime.properties remote LOG4J host with ${LOG4J_HOST:-localhost}:${LOG4J_PORT:-4445}"
            sed -i -- "s/__LOG4J_HOST__/${LOG4J_HOST:-localhost}/g" ${SERVICE_DIR}/runtime.properties 2>> /dev/null
            sed -i -- "s/__LOG4J_PORT__/${LOG4J_PORT:-4445}/g" ${SERVICE_DIR}/runtime.properties 2>> /dev/null
        fi

        if grep -q __LOG4J_HOST__ "${SERVICE_DIR}/log4j.properties" || grep -q __LOG4J_PORT__ "${SERVICE_DIR}/log4j.properties" ; then
            echo -e "\e[32mINFO\e[39m: Updating ${CIDS_SERVER_DIR}/log4j.properties remote LOG4J host with ${LOG4J_HOST:-$DOCKER_HOST_IP}:${LOG4J_PORT:-4445}"
            sed -i -- "s/__LOG4J_HOST__/${LOG4J_HOST:-$DOCKER_HOST_IP}/g" ${SERVICE_DIR}/log4j.properties 2>> /dev/null
            sed -i -- "s/__LOG4J_PORT__/${LOG4J_PORT:-4445}/g" ${SERVICE_DIR}/log4j.properties 2>> /dev/null
        fi
    fi
done