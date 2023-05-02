#!/bin/bash

TARGET_SERVER_PATH=${CIDS_DISTRIBUTION_DIR}/server

if [ ! -d "${SOURCE_SERVER_PATH}" ]; then
    echo "SOURCE_SERVER_PATH is not a valid directory" > /dev/stderr
    exit 1;
fi

cd ${SOURCE_SERVER_PATH}
for SERVER_DIR in $(ls -1 .); do
    SOURCE_SERVER_DIR=${SOURCE_SERVER_PATH}/${SERVER_DIR}
    TARGET_SERVER_DIR=${TARGET_SERVER_PATH}/${SERVER_DIR}

    SOURCE_RUNTIME_PROPERTIES=${SOURCE_SERVER_DIR}/runtime.properties
    TARGET_RUNTIME_PROPERTIES=${TARGET_SERVER_DIR}/runtime.properties
    if [ -f  "${SOURCE_RUNTIME_PROPERTIES}" ]; then
        sed -E "$RUNTIME_PROPERTIES_SED" > "${TARGET_RUNTIME_PROPERTIES}"
    fi
done
