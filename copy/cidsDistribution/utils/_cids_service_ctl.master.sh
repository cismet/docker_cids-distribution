#!/bin/bash

cd $SERVICE_DIR

### SLACKER
# -----------------------------------------------------------------------------------------

SLACK_MESSAGE_START=":rocket: cids Service *${SERVICE} [${DISTRIBUTION_NAME}]* started"
SLACK_MESSAGE_STOP=":cancel: cids Service *${SERVICE} [${DISTRIBUTION_NAME}]* stopped"
SLACK_MESSAGE_KILL=":skull: cids Service *${SERVICE} [${DISTRIBUTION_NAME}]* killed"

function slack {
  if [ ! -z "${SLACK_CHANNEL}" -a ! -z "${SLACK_HOOK}" ]; then
    SLACK_MESSAGE=$1
    SLACKER="slack.sh -u \"${SLACK_USER}\" -m \"${SLACK_MESSAGE}\" -c \"${SLACK_CHANNEL}\" -i \":suspension_railway:\""
    eval "$SLACKER"
  fi
}

### CMD
# -----------------------------------------------------------------------------------------

MEM_FLAGS=
[ -n "$XMS" ] && {
  MEM_FLAGS="$MEM_FLAGS -Xms$XMS"
}
[ -n "$XMX" ] && {
  MEM_FLAGS="$MEM_FLAGS -Xmx$XMX"
}

##################################
echo DEBUGPORT $DEBUGPORT
DEBUGGING=
[ -n "$DEBUGPORT" ] && {
  DEBUGGING="-agentlib:jdwp=transport=dt_socket,address=$DEBUGPORT,suspend=n,server=y"
}
##################################

JOLOKIA_FLAG=
[ -f "jolokia.properties" ] && {
  JOLOKIA_FLAG="-javaagent:/cidsDistribution/utils/jolokia-jvm-agent.jar=config=jolokia.properties"
}

R_FLAG=
if [ ! -z "${RUNTIME_PROPERTIES}" ]; then 
  if [ ! -z "${REST_API}" -a "${REST_API}" == "true" ]; then 
    R_FLAG="@${RUNTIME_PROPERTIES}"; 
  else
    R_FLAG="-r ${RUNTIME_PROPERTIES}"; 
  fi
fi
CMD="java -server ${JOLOKIA_FLAG} ${DEBUGGING} -XX:+HeapDumpOnOutOfMemoryError ${MEM_FLAGS} -D${CIDS_ACCOUNT_EXTENSION}=$SERVICE -Djava.awt.headless=true -Djava.security.policy=${CIDS_DISTRIBUTION_DIR}/policy.file -Dlog4j.configuration=file:log4j.properties -jar $SERVICE ${R_FLAG}"
if [ ! -z "$START_OPTIONS" ]; then
  CMD="$CMD $START_OPTIONS"
fi 

### IMPOSTORCHECK 
# -----------------------------------------------------------------------------------------

if [ ! -f $SERVICE ]; then
  ${CIDS_DISTRIBUTION_DIR}/utils/create_impostor.sh $SERVICE_DIR $STARTER_JAR $SERVICE
fi 

### START/STOP/RESTART
# -----------------------------------------------------------------------------------------

umask 0000

PID_FILE=$SERVICE_DIR/$SERVICE.pid
OUT_FILE=$SERVICE_DIR/$SERVICE.out

case "$1" in

  start)
    echo -e "\e[32mINFO\e[39m: $CMD"

    if [ -f "$PID_FILE" ]; then
      rm -f "$PID_FILE"
    fi
    if [ -f "$OUT_FILE" ]; then
      rm -f "$OUT_FILE"
    fi

    touch "$OUT_FILE"
    nohup $CMD &>> "$OUT_FILE" & RESULT=$?
    PID=$!

    slack "${SLACK_MESSAGE_START}"

    if [ "$RESULT" -ne 0 ]; then
      echo -e "\e[31mERROR\e[39m: \e[1m$SERVICE\e[0m could not be started: $RESULT"
    else
      sleep 3
      ps $PID | grep -q "$CMD"
      
      if [ "$?" -ne 0 ]; then
        echo -e "\e[33mWARN\e[39m: \e[1m$SERVICE\e[0m: 'ps' not successfull for PID $PID, trying 'jps'!"
        jps | grep -q "$SERVICE"
      fi

      if [ "$?" -ne 0 ]; then
        echo -e "\e[31mERROR\e[39m: \e[1m$SERVICE\e[0m failed during start: $?"
      else
        echo $! > "$PID_FILE"
        chmod g+w "$OUT_FILE"
        chmod g+w "$PID_FILE"
        echo -e "\e[32mINFO\e[39m: \e[1m$SERVICE\e[0m running ($PID)"

        if [ -x startup_hook.sh ]; then
          echo -e "\e[32mINFO\e[39m: running \e[1m$SERVICE\e[0m startup hook"
          ./startup_hook.sh
        fi
      fi
    fi
  ;;

   stop)
    if [ -f "$PID_FILE" ]; then
    kill `cat "$PID_FILE"`
      slack "${SLACK_MESSAGE_STOP}"
      sleep 3
    
      if [ "$?" -ne 0 ]; then
    echo -e "\e[31mERROR\e[39m: \e[1m$SERVICE\e[0m could not be stopped, trying to kill service"
    kill -9 `cat "$PID_FILE"`
        slack "${SLACK_MESSAGE_KILL}"
      fi

    rm -f "$PID_FILE"
    echo -e "\e[32mINFO\e[39m: \e[1m$SERVICE\e[0m stopped"
      
      if [ -x shutdown_hook.sh ]; then
        echo -e "\e[32mINFO\e[39m: running \e[1m$SERVICE\e[0m shutdown hook"
        ./shutdown_hook.sh
      fi  

  else
    echo -e "\e[33mWARN\e[39m: \e[1m$SERVICE\e[0m not running"
  fi  
  ;;
    
  restart)
    $0 stop
    $0 start
  ;;

  *)
  echo "Usage: $0 {start|stop|restart}"
  exit 1
  ;;
esac