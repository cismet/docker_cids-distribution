### GO TO DIRECTORY 
# -----------------------------------------------------------------------------------------
#SERVICE_DIR=${CIDS_DISTRIBUTION_DIR}/server/
#SERVICE_DIR=$((readlink -f $0)|sed "s/cs_ctl.sh//")
# echo CD to $SERVICE_DIR
cd $SERVICE_DIR

# .PID and .OUT files created on docker hosted (in host-mounted service/ volume) belong to root!
umask 0000

PID_FILE=$SERVICE_DIR/$SERVICE.pid
OUT_FILE=$SERVICE_DIR/$SERVICE.out

MEM_FLAGS=
[ -n "$XMS" ] && {
    MEM_FLAGS="$MEM_FLAGS -Xms$XMS"
}
[ -n "$XMX" ] && {
    MEM_FLAGS="$MEM_FLAGS -Xmx$XMX"
}


CMD="java -server -XX:+HeapDumpOnOutOfMemoryError ${MEM_FLAGS} -D${CIDS_ACCOUNT_EXTENSION}=$SERVICE -Djava.awt.headless=true -Djava.security.policy=${CIDS_DISTRIBUTION_DIR}/policy.file -Dlog4j.configuration=file:log4j.properties -jar $SERVICE"
if [ ! -z "$START_OPTIONS" ]; then
    CMD="$CMD $START_OPTIONS"
fi 

### IMPOSTORCHECK 
# -----------------------------------------------------------------------------------------
if [ ! -f $SERVICE ]; then
    # echo -e "\e[32mINFO\e[39m: creating impostor $SERVICE for $STARTER_JAR in $SERVICE_DIR"
    ${CIDS_DISTRIBUTION_DIR}/utils/create_impostor.sh $SERVICE_DIR $STARTER_JAR $SERVICE
    cd $SERVICE_DIR
fi 

case "$1" in

     stop)
        if [ -f "$PID_FILE" ]; then
	    kill `cat "$PID_FILE"`
            sleep 3
	    
            if [ "$?" -ne 0 ]; then
		echo -e "\e[31mERROR\e[39m: \e[1m$SERVICE\e[0m could not be stopped, trying to kill service"
		kill -9 `cat "$PID_FILE"`
		#kill -9  `ps -e -o pid,cmd,args|grep 'D'${CIDS_ACCOUNT_EXTENSION}|grep registry|cut -f 1 --delimiter=" "`
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
	
    start)
        if [ -f "$PID_FILE" ]; then
	    PID=`cat $PID_FILE`
	    ps $PID | grep -q "$CMD"
	    
	    if [ "$?" -eq 0 ]; then
	        echo -e "\e[32mINFO\e[39m: \e[1m$SERVICE\e[0m already running (PID: $PID)"
	    else
	        echo -e "\e[33mWARN\e[39m: \e[1m$SERVICE\e[0m: stale pid ($PID), removing $SERVICE.pid file and starting service again!"
		rm -f "$PID_FILE"
                $0 start
            fi
        else
            echo -e "\e[32mINFO\e[39m: $CMD"

            if [ -f "$OUT_FILE" ]; then
                rm -f "$OUT_FILE"
            fi

            touch "$OUT_FILE"
            nohup $CMD &>> "$OUT_FILE" & RESULT=$?
            PID=$!

            if [ "$RESULT" -ne 0 ]; then
                echo -e "\e[31mERROR\e[39m: \e[1m$SERVICE\e[0m could not be started: $RESULT"
                # exit 1
            else
                sleep 3
                ps $PID | grep -q "$CMD"
                
                if [ "$?" -ne 0 ]; then
                    echo -e "\e[33mWARN\e[39m: \e[1m$SERVICE\e[0m: 'ps' not successfull for PID $PID, trying 'jps'!"
                    jps | grep -q "$SERVICE"
                fi

                if [ "$?" -ne 0 ]; then
                    echo -e "\e[31mERROR\e[39m: \e[1m$SERVICE\e[0m failed during start: $?"
                    # exit 1
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
