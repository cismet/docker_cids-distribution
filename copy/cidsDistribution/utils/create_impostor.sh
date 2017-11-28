#!/bin/bash

if [[ -z $1 || -z $2 || -z $3 ]] ; then
   echo -e "\e[31mERROR\e[39m: Usage: $0 {SERVICE_DIR} {STARTER_JAR} {SERVICE}"
    exit 1
fi

SERVICE_DIR=$1
STARTER_JAR=$2
SERVICE=$3



umask 0000

mkdir -p .impostor.tmp
cd .impostor.tmp

jar -xf ${CIDS_STARTER_DIR}/$STARTER_JAR META-INF/MANIFEST.MF
MAIN_CLASS=$(sed -ne '/^Main-Class:/,/Class-Path:/ p' META-INF/MANIFEST.MF | sed -e '/^Class-Path:/ d' -e 's/^ //' | tr -d '\n\r')
rm META-INF/*
echo -e "\e[32mINFO\e[39m: creating impostor \e[1m$SERVICE\e[0m for $STARTER_JAR with main class $MAIN_CLASS"
printf "$MAIN_CLASS\n" > MANIFEST.TXT
#printf "Class-Path: ${CIDS_STARTER_DIR}/$STARTER_JAR\n">> MANIFEST.TXT
RELATIVE_CIDS_STARTER_DIR=`realpath --relative-to=$SERVICE_DIR $CIDS_STARTER_DIR`
echo $RELATIVE_CIDS_STARTER_DIR 
printf "Class-Path: $RELATIVE_CIDS_STARTER_DIR/$STARTER_JAR\n">> MANIFEST.TXT
jar -cfm $SERVICE MANIFEST.TXT -C META-INF .
mv $SERVICE $SERVICE_DIR/$SERVICE
cd ..
rm -rf .impostor.tmp