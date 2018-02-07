#!/bin/bash

################################################################################
# BUILD-script for cids Legacy- and AutoDistributions
# Creates  a _security_jar for a provided JNLP file 
#
# This behaviour is currently inconsitent with cids auto distribution (cids-maven-plugin v5.0).   
# See https://github.com/cismet/cids-docker-images/issues/15 for explanation
#
################################################################################

if [[ -z $1 ]] ; then
    echo -e "\e[31mERROR\e[39m: Usage: $0 {JNLP FILE}"
    exit 1
elif [[ -f ${CIDS_DISTRIBUTION_DIR}/.private/keystore && ${CIDS_DISTRIBUTION_DIR}/.private/keystore.pwd ]]; then
    JNLP_FILE=$1

    # JNLP generated by autodistribution ...
    if [[ "$JNLP_FILE" == *-starter.jnlp ]] ; then
        JNLP_BASE=$(basename "$JNLP_FILE" -starter.jnlp)
    else
        JNLP_BASE=$(basename "$JNLP_FILE" .jnlp)
    fi

    echo -e "\e[32mINFO\e[39m: Creating ${JNLP_BASE}_security.jar for $JNLP_FILE"
    umask 0000
    # replace security-jar-template.jar classpath entry in JNLP generated by old autodistribution (in local dir)
    sed -i -- "s/local${CIDS_ACCOUNT_EXTENSION}\/security-jar-template.jar\"/classpath${CIDS_ACCOUNT_EXTENSION}\/${JNLP_BASE}_security.jar\" main=\"true\"/g" $JNLP_FILE
    # replace security created by new autodistribution (in client dir, lowercase)
    sed -i -- "s/client\/${CIDS_ACCOUNT_EXTENSION,,}\/${JNLP_BASE}_security.jar\"/lib\/classpath${CIDS_ACCOUNT_EXTENSION}\/${JNLP_BASE}_security.jar\" main=\"true\"/g" $JNLP_FILE
    # replace security created by new autodistribution (in client dir, uppercase)
    sed -i -- "s/client\/${CIDS_ACCOUNT_EXTENSION}\/${JNLP_BASE}_security.jar\"/lib\/classpath${CIDS_ACCOUNT_EXTENSION}\/${JNLP_BASE}_security.jar\" main=\"true\"/g" $JNLP_FILE
    # replace security jar in legacy cids distribution JNLP created by ABF
    sed -i -- "s/client\/${JNLP_BASE}_security.jar\"/lib\/classpath${CIDS_ACCOUNT_EXTENSION}\/${JNLP_BASE}_security.jar\" main=\"true\"/g" $JNLP_FILE
    
    rm -rf JNLP-INF 2>> /dev/null
    rm -f MANIFEST.TXT 2>> /dev/null

    mkdir -p JNLP-INF
    cp $JNLP_FILE JNLP-INF/APPLICATION.JNLP

    printf "Permissions: all-permissions\n" > MANIFEST.TXT
    printf "Codebase: *\n" >> MANIFEST.TXT
    printf "Caller-Allowable-Codebase: *\n" >> MANIFEST.TXT
    printf "Application-Library-Allowable-Codebase: *\n" >> MANIFEST.TXT
    printf "Application-Name: cids Navigator\n" >> MANIFEST.TXT
    printf "Trusted-Only: true\n" >> MANIFEST.TXT
    printf "Sealed: true\n" >> MANIFEST.TXT
    printf "\n" >> MANIFEST.TXT

    jar -cfm ${JNLP_BASE}_security.jar MANIFEST.TXT JNLP-INF
    
    # copy security jar to classpath directory of the image
    mkdir -p ${CIDS_LIB_DIR}/classpath${CIDS_ACCOUNT_EXTENSION} 2> /dev/null
    mv ${JNLP_BASE}_security.jar ${CIDS_LIB_DIR}/classpath${CIDS_ACCOUNT_EXTENSION}/
    ${CIDS_DISTRIBUTION_DIR}/utils/sign.sh ${CIDS_DISTRIBUTION_DIR}/.private/keystore `cat ${CIDS_DISTRIBUTION_DIR}/.private/keystore.pwd` "http://dse200.ncipher.com/TSS/HttpTspServer" ${CIDS_LIB_DIR}/classpath${CIDS_ACCOUNT_EXTENSION}/${JNLP_BASE}_security.jar
    echo -e "\e[32mINFO\e[39m: ${JNLP_BASE}_security.jar copied to ${CIDS_LIB_DIR}/classpath${CIDS_ACCOUNT_EXTENSION}/"

    # copy JNLP to starter directory of the image 
    # -> on container start the JNLP is copied back to the **host mounted** /client directory! 
    # (see import/container_ctl.sh)
    mkdir -p ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION} 2> /dev/null
    cp $JNLP_FILE ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/ 2>> /dev/null

    rm -rf JNLP-INF 2>> /dev/null
    rm -f MANIFEST.TXT 2>> /dev/null
    echo -e "\e[32mINFO\e[39m: ${JNLP_BASE}.jnlp copied to ${CIDS_LIB_DIR}/starter${CIDS_ACCOUNT_EXTENSION}/"
else
    echo -e "\e[31mERROR\e[39m: Could not sign all JAR file for \e[1m$1\e[0m, keystore not available"
    # hard fail
    exit 1
fi