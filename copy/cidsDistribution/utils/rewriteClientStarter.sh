#!/bin/bash

if [ -z "${EXTRA_STARTER_HOST}" ] || [ -z "${EXTRA_STARTER_SUFFIX}" ]; then
	echo "EXTRA_STARTER_HOST not set, aborting !" > /dev/stderr
	exit 1;
fi

SED_SEARCH="cids-live.s10222.wuppertal-intra.de"
SED_REPLACE="${EXTRA_STARTER_HOST}"
SED_COMMAND='s/'${SED_SEARCH}'/'${SED_REPLACE}'/g'

KEYSTORE="${CIDS_DISTRIBUTION_DIR}/.private/keystore"
STOREPASS=$(cat "${CIDS_DISTRIBUTION_DIR}/.private/keystore.pwd")

SUFFIX="${EXTRA_STARTER_SUFFIX}"

mkdir -p "${CIDS_DISTRIBUTION_DIR}/lib/classpathWuNDa-${SUFFIX}/"
for CLASSPATH_ORIG in $(ls -1 "${CIDS_DISTRIBUTION_DIR}"/lib/classpathWuNDa/*-classpath.jnlp); do
    # create extra classpath from orig classpath
    CLASSPATH_NAME=$(basename ${CLASSPATH_ORIG})
    CLASSPATH_EXTRA="${CIDS_DISTRIBUTION_DIR}/lib/classpathWuNDa-${SUFFIX}/${CLASSPATH_NAME}"
    sed ${SED_COMMAND} "${CLASSPATH_ORIG}" > "${CLASSPATH_EXTRA}"
done

mkdir -p "${CIDS_DISTRIBUTION_DIR}/client/WuNDa-${SUFFIX}/"
for STARTER_ORIG in $(ls -1 "${CIDS_DISTRIBUTION_DIR}"/client/WuNDa/*-starter.jnlp); do
    # create extra starter from orig starter
    STARTER_NAME=$(basename ${STARTER_ORIG})
    STARTER_EXTRA="${CIDS_DISTRIBUTION_DIR}/client/WuNDa-${SUFFIX}/${STARTER_NAME}"
    sed ${SED_COMMAND}';s#classpathWuNDa#classpathWuNDa-'${SUFFIX}'#g;s#client/WuNDa#client/WuNDa-'${SUFFIX}'#g;' "${STARTER_ORIG}" > "${STARTER_EXTRA}"

    # create security jar
    SECURITY_NAME=${STARTER_NAME%%-starter.jnlp}_security.jar
    SECURITY_ORIG="${CIDS_DISTRIBUTION_DIR}/client/WuNDa/${SECURITY_NAME}"
    SECURITY_EXTRA="${CIDS_DISTRIBUTION_DIR}/client/WuNDa-${SUFFIX}/${SECURITY_NAME}"
    SECURITY_TMP="/tmp/${SECURITY_NAME}"
    ## unpack orig jar to tmp
    unzip -qq -d $SECURITY_TMP $SECURITY_ORIG
    ## remove old certificates
    rm "${SECURITY_TMP}/META-INF/CISMET.SF" "${SECURITY_TMP}/META-INF/CISMET.RSA"
    ## copy extra starter to APPLICATION.JNLP
    cp "${STARTER_EXTRA}" "${SECURITY_TMP}/JNLP-INF/APPLICATION.JNLP"
    ## pack new jar from tmp
    cd "${SECURITY_TMP}" && zip -qq -r "${SECURITY_EXTRA}" * && cd -
    ## sign new jar
    "${CIDS_DISTRIBUTION_DIR}/utils/sign.sh" ${KEYSTORE} ${STOREPASS} ${TSA_SERVER} ${SECURITY_EXTRA}
    ## cleanup
    rm -r "${SECURITY_TMP}"
done

APPS_ORIG_DIR="${CIDS_DISTRIBUTION_DIR}/apps/"
APPS_EXTRA_DIR="${CIDS_DISTRIBUTION_DIR}/apps-${SUFFIX}"
if [ -d "${APPS_ORIG_DIR}" ]; then
    rm -rf "${APPS_EXTRA_DIR}"
    mkdir "${APPS_EXTRA_DIR}"
    ln -sf "${APPS_ORIG_DIR}/.libs" "${APPS_EXTRA_DIR}/.libs"
    for GETDOWN_ORIG in $(ls -1 "${APPS_ORIG_DIR}"/*/*/getdown.txt); do
        GETDOWN_ORIG_DIR=${GETDOWN_ORIG%%/getdown.txt}
        GETDOWN_NAME=$(basename ${GETDOWN_ORIG_DIR})
        GETDOWN_EXTRA_DIR="${APPS_EXTRA_DIR}/${GETDOWN_ORIG_DIR##${APPS_ORIG_DIR}/}"
        mkdir -p "${GETDOWN_EXTRA_DIR}"
        cp "${GETDOWN_ORIG_DIR}"/* "${GETDOWN_EXTRA_DIR}"
        GETDOWN_EXTRA="${GETDOWN_EXTRA_DIR}/getdown.txt"
        sed -i ${SED_COMMAND}';s#client/WuNDa#client/WuNDa-'${SUFFIX}'#g;s#/apps/#/apps-'${SUFFIX}'/#g' "${GETDOWN_EXTRA}"; 
        java -classpath ${CIDS_DISTRIBUTION_DIR}/lib/m2/com/threerings/getdown/getdown-core/1.8.6/getdown-core-1.8.6.jar com.threerings.getdown.tools.Digester ${GETDOWN_EXTRA_DIR}
    done
fi
