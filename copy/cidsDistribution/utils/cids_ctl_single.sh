#!/bin/bash

export CIDS_STARTER_DIR=${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}

### FUNCTIONS 
# -----------------------------------------------------------------------------------------

SERVERS_PATH="${CIDS_DISTRIBUTION_DIR}/server"
CIDS_CTL_FILE="${SERVERS_PATH}/.cids_ctl"

pull() {
    /cidsDistribution/utils/checkoutFromRepo.sh
}

prepare() {
    CIDS_CTL_DIR="/tmp/cids-ctl_$(echo $RANDOM | md5sum | head -c 20)";
    mkdir -p "${CIDS_CTL_DIR}"

    RUNTIME_PROPERTY_REGEX="^RUNTIME_PROPERTY_(.*)=(.*)$"
    RUNTIME_PROPERTY_KEY_MATCH="\\1"
    RUNTIME_PROPERTY_VALUE_MATCH="\\2"
    while read -r ENV_RUNTIME_PROPERTY; do
        RUNTIME_PROPERTY_KEY=("$(echo "${ENV_RUNTIME_PROPERTY}" | sed -E 's#'"$RUNTIME_PROPERTY_REGEX"'#'"$RUNTIME_PROPERTY_KEY_MATCH"'#')")
        RUNTIME_PROPERTY_VALUE=("$(echo "${ENV_RUNTIME_PROPERTY}" | sed -E 's#'"$RUNTIME_PROPERTY_REGEX"'#'"$RUNTIME_PROPERTY_VALUE_MATCH"'#')")
        if [ ! -z "${REST_API}" -a "${REST_API}" == "true" ]; then
            APPEND_RUNTIME_PROPERTIES+="-${RUNTIME_PROPERTY_KEY} = ${RUNTIME_PROPERTY_VALUE}\n"
        else
            APPEND_RUNTIME_PROPERTIES+="${RUNTIME_PROPERTY_KEY}=${RUNTIME_PROPERTY_VALUE}\n"
        fi
    done <<< $(env | grep -E "$RUNTIME_PROPERTY_REGEX")

    ORIG_RUNTIME_PROPERTIES=${SERVICE_DIR}/runtime.properties
    RUNTIME_PROPERTIES="${ORIG_RUNTIME_PROPERTIES}"
    if [ ! -z "${APPEND_RUNTIME_PROPERTIES}" ]; then
        TMP_RUNTIME_PROPERTIES="${CIDS_CTL_DIR}/runtime.properties"
        echo -e "$(
            sed -E 's#^(.*)=(\w*)runtime.properties\s*$#\1=\2'"${TMP_RUNTIME_PROPERTIES}"'#g' ${ORIG_RUNTIME_PROPERTIES}
            if [ ! -z "${REST_API}" -a "${REST_API}" == "true" ]; then
                echo -e "\n-properties.appended = true"
            else
                echo -e "\nproperties.appended=true"
            fi
            echo -e "\n${APPEND_RUNTIME_PROPERTIES}"
        )" > "${TMP_RUNTIME_PROPERTIES}"
        RUNTIME_PROPERTIES="${TMP_RUNTIME_PROPERTIES}"
    fi;

    ORIG_DOT_INTEGRITY="${SERVICE_DIR}/.integrity"
    TMP_DOT_INTEGRITY="${CIDS_CTL_DIR}/.integrity"
    DOT_INTEGRITY="${ORIG_DOT_INTEGRITY}"
    if [ -f "${ORIG_DOT_INTEGRITY}" ]; then
        echo -e "$(
            echo -e "RUNTIME_PROPERTIES=${RUNTIME_PROPERTIES}\n"
            sed -E 's#^jdbc_properties="?runtime.properties"?\s*$#jdbc_properties='"${TMP_RUNTIME_PROPERTIES}"'#g' "${ORIG_DOT_INTEGRITY}"
            echo -e "checks_parent_dir=\"${SERVICE_DIR}\""
        )" > "${TMP_DOT_INTEGRITY}"
        DOT_INTEGRITY="${TMP_DOT_INTEGRITY}"
    fi

    STARTER_JAR=${STARTER_JAR:-${SERVICE}-starter.jar}

    CIDS_CTL_FILE="${SERVERS_PATH}/.cids_ctl"
    cat << EOF > "${CIDS_CTL_FILE}"
#!/bin/bash

# $(date)
export RUNTIME_PROPERTIES=${RUNTIME_PROPERTIES}
export DOT_INTEGRITY=${DOT_INTEGRITY}
export SERVICE_DIR=${SERVICE_DIR}
export STARTER_JAR=${STARTER_JAR}
EOF
}

start_server() {
    if [ -f ${CIDS_CTL_FILE} ]; then
        source ${CIDS_CTL_FILE}
    fi

    export RUNTIME_PROPERTIES STARTER_JAR START_OPTIONS XMS XMX DEBUGPORT REST_API
    ${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh start
}

stop_server() {

    CIDS_CTL_FILE="${SERVERS_PATH}/.cids_ctl"
    if [ -f ${CIDS_CTL_FILE} ]; then
        source ${CIDS_CTL_FILE}
    fi

    ${CIDS_DISTRIBUTION_DIR}/utils/_cids_service_ctl.master.sh stop
}

log() {
    CIDS_CTL_FILE="${SERVERS_PATH}/.cids_ctl"
    if [ -f ${CIDS_CTL_FILE} ]; then
        source ${CIDS_CTL_FILE}
    fi

    cat ${SERVICE_DIR}/${SERVICE}.out
}

follow() {
    CIDS_CTL_FILE="${SERVERS_PATH}/.cids_ctl"
    if [ -f ${CIDS_CTL_FILE} ]; then
        source ${CIDS_CTL_FILE}
    fi

    tail -f ${SERVICE_DIR}/${SERVICE}.out
}

integrity() {
    CHECK_FOLDER=$1
    
    CIDS_CTL_FILE="${SERVERS_PATH}/.cids_ctl"
    if [ -f ${CIDS_CTL_FILE} ]; then
        source ${CIDS_CTL_FILE}
    fi

    if [ -f "${DOT_INTEGRITY}" ]; then
        cd "${SERVICE_DIR}"
        teg -i "${DOT_INTEGRITY}" "${CHECK_FOLDER}"
    else
        echo "Sorry, There is no .integrity file. I can't execute integrity checks..."
    fi    
}

### OPTIONS
# -----------------------------------------------------------------------------------------

case "$1" in
    
    pull)
        pull
    ;;

    prepare)
        prepare
    ;;

    start)
        start_server
    ;;
	
    stop)
        stop_server
    ;;
    
    restart)
        $0 stop
        $0 start
    ;;

    integrity)
        CHECK_FOLDER=$2
        integrity ${CHECK_FOLDER}
    ;;

    follow)
        follow
    ;;

    log)
        log
    ;;

    *)
        echo "Usage: $0 {pull|prepare|start|stop|restart|log|follow|integrity {CHECK_FOLDER (optional)}}"
    ;;

esac