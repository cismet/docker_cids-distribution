#!/bin/bash

function finish {
    echo -e "\e[32mINFO\e[39m: stopping cids services"
    ${CIDS_DISTRIBUTION_DIR}/cids_ctl.sh stop
    echo -e "\e[32mINFO\e[39m: cids services stopped"
    
    if [[ "${CIDSCTL_START_WEBSERVER}" = "true" ]]; then
        echo -e "\e[32mINFO\e[39m: stopping nginx"
        service nginx stop
        echo -e "\e[32mINFO\e[39m: nginx stopped"
    fi

    if [[ -x /shutdown_hook.sh ]]; then
        echo -e "\e[32mINFO\e[39m: running \e[1m$CONTAINER\e[0m shutdown hook"
        /shutdown_hook.sh
    fi

    exit 0
}

function is_ready {
    eval "psql -h $CIDS_INTEGRATION_BASE_PORT_5432_TCP_ADDR -U postgres -c \"DROP TABLE IF EXISTS isready; CREATE TABLE isready (); COPY isready FROM '/tmp/isready.csv' DELIMITER ';' CSV HEADER\""
}

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap finish HUP INT QUIT TERM SIGUSR1


if [[ "${CIDSCTL_CHECK_DATABASE_CONNECTION}" = "true" ]]; then
    # FIXME!
    # Environment variables are no longer the recommended method for connecting to linked services. 
    # Instead, you should use the link name (by default, the name of the linked service) as the hostname to connect to. 
    # See the docker-compose.yml documentation for details.
    # Environment variables will only be populated if you’re using the legacy version 1 Compose file format.
    echo -e "\e[32mINFO\e[39m: ###### CHECKING CIDS INTEGRATION BASE CONTAINER ######"
    if test -z "${CIDS_INTEGRATION_BASE_PORT_5432_TCP_ADDR}" -o -z "${CIDS_INTEGRATION_BASE_PORT_5432_TCP_PORT}"; then
        echo -e "\e[33mERROR\e[39m: Container not linked with PostgreSQL container cids-integration-base"
    else
        echo -e "\e[32mINFO\e[39m: container linked with PostgreSQL container cids-integration-base (${CIDS_INTEGRATION_BASE_PORT_5432_TCP_ADDR}:${CIDS_INTEGRATION_BASE_PORT_5432_TCP_PORT})"
        i=0
        while ! is_ready;
        do 
            i=`expr $i + 1`
            if [ $i -ge 20 ]; then
                echo -e "\e[31mERROR\e[39m: $(date) - cids integration base PostgreSQL (${CIDS_INTEGRATION_BASE_PORT_5432_TCP_ADDR}:${CIDS_INTEGRATION_BASE_PORT_5432_TCP_PORT}) service still not ready, giving up"
                exit 1
            fi
            echo -e "\e[33mWARN\e[39m: $(date) - waiting for cids integration base PostgreSQL service (${CIDS_INTEGRATION_BASE_PORT_5432_TCP_ADDR}:${CIDS_INTEGRATION_BASE_PORT_5432_TCP_PORT}) to be ready"
            sleep 15
        done
    fi
else
	echo -e "\e[33mWARN\e[39m: Container not linked with PostgreSQL container cids-integration-base. CIDSCTL_CHECK_DATABASE_CONNECTION=${CIDSCTL_CHECK_DATABASE_CONNECTION}"
fi

echo -e "\e[32mINFO\e[39m: ###### UPDATING SERVER CONFIGURATION ######"
${CIDS_DISTRIBUTION_DIR}/utils/update_configuration.sh

echo -e "\e[32mINFO\e[39m: ###### UPDATING CLIENT CONFIGURATION ######"
# copy JNLP generated when image was built to the client dir on the host-mounted volume!
#
# This behaviour is currently inconsitent with cids auto distribution (cids-maven-plugin v5.0). 
# See https://github.com/cismet/cids-docker-images/issues/15
umask 0000

if [[ -d ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION,,} ]]; then
    # Autodistibution: subdir ${CIDS_ACCOUNT_EXTENSION,,} below client dir (,, -> lowercase!)
    echo -e "\e[32mINFO\e[39m: Copy JNLP files to host mounted volume ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION,,}/"
    find ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/ -name "*.jnlp" -type f -exec cp {} ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION,,}/ \;
    #workaround for #15: restore _security.jar generated by new autodistribution in copy_client_starter.sh
    find ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/ -name "*_security.jar" -type f -exec cp {} ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION,,}/ \;
elif [[ -d ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION} ]]; then
    # Autodistibution: subdir ${CIDS_ACCOUNT_EXTENSION} below client dir (,, -> lowercase!)
    echo -e "\e[32mINFO\e[39m: Copy JNLP files to host mounted volume ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION}/"
    find ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/ -name "*.jnlp" -type f -exec cp {} ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION}/ \;
    #workaround for #15: restore _security.jar generated by new autodistribution in copy_client_starter.sh
    find ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/ -name "*_security.jar" -type f -exec cp {} ${CIDS_CLIENT_DIR}/${CIDS_ACCOUNT_EXTENSION}/ \;
else
    echo -e "\e[32mINFO\e[39m: Copy JNLP files to host mounted volume ${CIDS_CLIENT_DIR}/"
    find ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/ -name "*.jnlp" -type f -exec cp {} ${CIDS_CLIENT_DIR}/ \;
    #workaround for #15: restore _security.jar generated by new autodistribution in copy_client_starter.sh
    find ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/ -name "*_security.jar" -type f -exec cp {} ${CIDS_CLIENT_DIR}/ \;
fi

echo -e "\e[32mINFO\e[39m: ###### STARTING SERVICES ######"
# start service in background here
echo -e "\e[32mINFO\e[39m: starting cids services"
${CIDS_DISTRIBUTION_DIR}/cids_ctl.sh start

if [[ "${CIDSCTL_START_WEBSERVER}" = "true" ]]; then
    echo -e "\e[32mINFO\e[39m: starting nginx"
    sed -i -- "s#__CIDS_DISTRIBUTION_DIR__#${CIDS_DISTRIBUTION_DIR:-/cidsDistribution}#g" /etc/nginx/sites-available/default
    service nginx start
fi

if [[ -x /startup_hook.sh ]]; then
    echo -e "\e[32mINFO\e[39m: running \e[1mCONTAINER\e[0m startup hook"
    /startup_hook.sh
fi

echo -e "\n\e[32mhit [CTRL+C] to exit or run 'docker stop <container>'\e[39m:\n"

while :
do
    # sleep in background in order to make the trap work
    # NOTE: 'read' does not work with docker-compose!
    sleep infinity &

    # wait for last background process (sleep)
    wait $!
    echo -e "\e[33mWARN\e[39m: container stopped with [CTRL+C]"
    exit 0
done