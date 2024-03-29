#!/bin/bash

export CIDS_STARTER_DIR=${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}

### FUNCTIONS 
# -----------------------------------------------------------------------------------------

SERVERS_PATH=${CIDS_DISTRIBUTION_DIR}/server

list_server_dirs() {
    cd ${SERVERS_PATH}
    ls -1 . | grep -E "^[0-9]{3}_.*$" | sort
}

list_services() {
    for SERVER_DIR in $(list_server_dirs); do
        SERVICE=${SERVER_DIR:4}
        SERVICE_DIR=${SERVERS_PATH}/${SERVER_DIR}
        ENV_FILE=${SERVICE_DIR}/ENV
        if [ -f ${ENV_FILE} ]; then
            source ${ENV_FILE}
        fi

        echo ${SERVICE}
    done
}

get_server_dir() {
    _SERVICE=$1

    for SERVER_DIR in $(list_server_dirs); do
        SERVICE=${SERVER_DIR:4}
        SERVICE_DIR=${SERVERS_PATH}/${SERVER_DIR}
        ENV_FILE=${SERVICE_DIR}/ENV
        if [ -f ${ENV_FILE} ]; then
            source ${ENV_FILE}
        fi

        if [ "${_SERVICE}" == "${SERVICE}" ]; then
            echo ${SERVER_DIR}
            exit 0
        fi        
    done
}

start_server() {
    SERVICE=$1
    SERVER_DIR=$(get_server_dir ${SERVICE})
    SERVICE_DIR=${SERVERS_PATH}/${SERVER_DIR}
    STARTER_JAR=${STARTER_JAR:-${SERVICE}-starter.jar}
    SLEEP_BEFORE_START=1
    ENV_FILE=${SERVICE_DIR}/ENV
    if [ -f ${ENV_FILE} ]; then
        source ${ENV_FILE}
    fi

    sleep ${SLEEP_BEFORE_START}
    export SERVICE SERVICE_DIR STARTER_JAR START_OPTIONS XMS XMX DEBUGPORT
    ${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh start
}

stop_server() {
    SERVICE=$1
    SERVER_DIR=$(get_server_dir ${SERVICE})    
    SERVICE_DIR=${SERVERS_PATH}/${SERVER_DIR}
    SLEEP_BEFORE_STOP=1
    ENV_FILE=${SERVICE_DIR}/ENV
    if [ -f ${ENV_FILE} ]; then
        source ${ENV_FILE}
    fi

    sleep ${SLEEP_BEFORE_STOP}

    export SERVICE SERVICE_DIR
    ${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh stop
}

log() {
    SERVICE=$1
    SERVER_DIR=$(get_server_dir ${SERVICE})    
    SERVICE_DIR=${SERVERS_PATH}/${SERVER_DIR}
    ENV_FILE=${SERVICE_DIR}/ENV
    if [ -f ${ENV_FILE} ]; then
        source ${ENV_FILE}
    fi

    cat ${SERVICE_DIR}/${SERVICE}.out
}

follow() {
    SERVICE=$1
    SERVER_DIR=$(get_server_dir ${SERVICE})    
    SERVICE_DIR=${SERVERS_PATH}/${SERVER_DIR}
    ENV_FILE=${SERVICE_DIR}/ENV
    if [ -f ${ENV_FILE} ]; then
        source ${ENV_FILE}
    fi

    tail -f ${SERVICE_DIR}/${SERVICE}.out
}

integrity() {
    SERVICE=$1
    CHECK_FORLDER=$2
    SERVER_DIR=$(get_server_dir ${SERVICE})    
    SERVICE_DIR=${SERVERS_PATH}/${SERVER_DIR}
    INTEGRITY_FILE=${SERVICE_DIR}/.integrity
    if [ -f ${INTEGRITY_FILE} ]; then
        cd ${SERVICE_DIR}
        teg ${CHECK_FORLDER}        
    else
        echo "Sorry, There is no .integrity file. I can't execute integrity checks..."
    fi    
}

### OPTIONS
# -----------------------------------------------------------------------------------------

case "$1" in
    
    start)
        SERVICE=$2        
        start_server ${SERVICE}
    ;;
	
    stop)
        SERVICE=$2
        stop_server ${SERVICE}
    ;;
    
    restart)
        SERVICE=$2
        $0 stop  ${SERVICE}
        $0 start ${SERVICE}
    ;;

    integrity)
        SERVICE=$2
        CHECK_FOLDER=$3
        integrity ${SERVICE} ${CHECK_FOLDER}
    ;;

    follow)
        SERVICE=$2
        follow ${SERVICE}
    ;;

    log)
        SERVICE=$2
        log ${SERVICE}
    ;;

    list_services)
        list_services
    ;;

    *)
        echo "Usage: $0 {list_services|{start|stop|restart|log|follow|integrity} {SERVICE (optional)}}"
    ;;

esac