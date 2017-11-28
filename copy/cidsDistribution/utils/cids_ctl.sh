#!/bin/bash

# General cids server control script

#export CIDS_DISTRIBUTION_DIR=/cidsDistribution <- already set in docker image
#export CIDS_SERVER_DIR=$CIDS_DISTRIBUTION_DIR/server <- already set in docker image

export CIDS_LOCAL_DIR=${CIDS_LIB_DIR}/local${CIDS_ACCOUNT_EXTENSION}
export CIDS_STARTER_DIR=${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}

### FUNCTIONS 
# -----------------------------------------------------------------------------------------

pattern='^[0-9]{3}_.+$'
cd $CIDS_SERVER_DIR

case "$1" in
    
    stop)
        for SERVICE_DIR in *; do
            if [[ -d $SERVICE_DIR && $SERVICE_DIR =~ $pattern ]]; then
                SERVICE=$(cat ${CIDS_SERVER_DIR}/$SERVICE_DIR/cs_ctl.sh | grep SERVICE | cut -f 2 -d "=")
                if [[ -z $2 || $2 = $SERVICE ]]; then
                    echo -e "\e[32mINFO\e[39m: stopping \e[1m$SERVICE\e[0m cids server process in $SERVICE_DIR/"
                    ${CIDS_SERVER_DIR}/$SERVICE_DIR/cs_ctl.sh $1
                    sleep 2
                fi
            fi
        done

        sleep 5
        ps -ef|grep 'D'${CIDS_ACCOUNT_EXTENSION}

        # not necessary anymore -> _cids_service_ctl.master.sh should take care to kill services
        for SERVICE_DIR in *; do
            if [[ -d $SERVICE_DIR && $SERVICE_DIR =~ $pattern ]]; then
                SERVICE=$(cat ${CIDS_SERVER_DIR}/$SERVICE_DIR/cs_ctl.sh | grep SERVICE | cut -f 2 -d "=")
                if [[ -z $2 || $2 = $SERVICE ]]; then
                    processId=jps | grep $SERVICE | cut -f 1 --delimiter=" "
                    if [[ -z $processId ]]; then
                        echo -e "\e[32mINFO\e[39m: \e[1m$SERVICE\e[0m cids server process in $SERVICE_DIR/ gracefully stopped"
                    else
                        echo -e "\e[33mWARN\e[39m: forcibly stopping \e[1m$SERVICE\e[0m cids server process in $SERVICE_DIR/ (PID: $processId)"
                        # run kill command 2 times 
                        for k in 1 2
                            do 
                                kill -9  $processId
                            done
                    fi
                fi
            fi
        done
    ;;
    
    start)
        for SERVICE_DIR in *; do
            if [[ -d $SERVICE_DIR && $SERVICE_DIR =~ $pattern ]]; then
                SERVICE=$(cat ${CIDS_SERVER_DIR}/$SERVICE_DIR/cs_ctl.sh | grep SERVICE | cut -f 2 -d "=")
                if [[ -z $2 || $2 = $SERVICE ]]; then
                    echo -e "\e[32mINFO\e[39m: starting \e[1m$SERVICE\e[0m cids server process in $SERVICE_DIR/"
                    $CIDS_SERVER_DIR/$SERVICE_DIR/cs_ctl.sh $1
                    sleep 10
                fi
            fi
        done

    	ps -ef|grep 'D'${CIDS_ACCOUNT_EXTENSION}
    ;;
	
    restart)
    	$0 stop $2
	$0 start $2
    ;;

    *)
	echo "Usage: $0 {start|stop|restart} {SERVICE (optional)}"
	exit 1
    ;;

esac
