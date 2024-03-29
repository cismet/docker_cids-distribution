#!/bin/bash
DIR=$(dirname "$(readlink -f "$0")")
PATH="${PATH}:${JAVA_HOME}/bin"

# external variables:
#  CLIENT_RESOURCES_PLAIN     (where are the sources)
#  CLIENT_RESOURCES_OVERWRITE (where are the overwrite sources)
#  CLIENT_RESOURCES_TARGET    (where should the compiled jars be build into)
#  CIDSDISTRIBUTION_HOST      (when modifying starters, which host should be used as a clients backreference host)
#  CIDS_DISTRIBUTION_DIR      (comes from the distribution project, almost certainly set to '/cidsDistribution')
#  CIDS_EXTENSION             (comes from the distribution project, probably 'WuNDa', 'WRRLDBMV' or something like that)

#####

SESSION="$(echo ${RANDOM} | md5sum | head -c 8)"
TMP_SESSION_DIR="/tmp/${SESSION}"

if [ ! -z "${CLIENT_RESOURCES_PLAIN}" ]; then
  DEFAULT_SOURCE=${CLIENT_RESOURCES_PLAIN}
elif [ ! -z "${GIT_TARGET_resources}" ] ; then
  DEFAULT_SOURCE="${GIT_TARGET_resources}/plain"
else
  DEFAULT_SOURCE="${DEFAULT_TARGET}/src/plain"
fi

if [ ! -z "${CLIENT_RESOURCES_TARGET}" ]; then
  DEFAULT_TARGET=${CLIENT_RESOURCES_TARGET}
else
  DEFAULT_TARGET="${CIDS_DISTRIBUTION_DIR}/lib/local${CIDS_EXTENSION}"
fi


KEYSTORE="${CIDS_DISTRIBUTION_DIR}/signing/keystore.jks"
KEYSTORE_PASS=$(cat "${CIDS_DISTRIBUTION_DIR}/signing/keystore.pass")
CLERKSTER_CREDS=$(cat "${CIDS_DISTRIBUTION_DIR}/signing/clerkster.creds")
CLERKSTER_USER=$(echo ${CLERKSTER_CREDS} | cut -d ":" -f 1)
CLERKSTER_PASS=$(echo ${CLERKSTER_CREDS} | cut -d ":" -f 2)

APPS="${CIDS_DISTRIBUTION_DIR}/apps"
APPLIBS="${APPS}/.libs"

#####

function unpackJar {
  destDir="$1"
  srcPath="$2"
  destPath="${destDir}/$(basename "${srcPath%%.jar}")"
  echo " * unpacking ${srcPath} => ${destPath}"
  unzip -qq "${srcPath}" -d "${destPath}"
}

function diffUnpackedJar {
  destDir="$1"
  srcPath="$2"
  destPath="${destDir}/$(basename "${srcPath}")"
  diff --exclude="META-INF" -r "${srcPath}" "${destPath}" > /dev/null
  return $?
}

function buildJar {
  destDir="$1"
  srcPath="$2"
  destPath="${destDir}/$(basename "${srcPath}").jar"
  echo " * building ${srcPath} => ${destPath}"
  jar cf "${destPath}" -C "${srcPath}" . 
}

function selfSignJar {
  destDir="$1"
  srcPath="$2"
  dstPath="${destDir}/$(basename "${srcPath}")"
  echo " * signing ${srcPath} => ${dstPath}"
  jarsigner -keystore "${KEYSTORE}" -signedjar "${dstPath}" "${srcPath}" wupp -storepass ${KEYSTORE_PASS} > /dev/null
}

function clerksterSignJar {
  destDir="$1"
  srcPath="$2"
  dstPath="${destDir}/$(basename ${srcPath})"
  echo " * signing ${srcPath} => ${dstPath}"
  curl -s -u${CLERKSTER_USER}:${CLERKSTER_PASS} -X POST -H "Content-Type: multipart/form-data" -F "upload=@${srcPath}" https://clerkster.cismet.de/upload > "${dstPath}"
}

function deployFile {
  destPath="$1"
  srcPath="$2"
  echo " * deploying ${srcPath} => ${destPath}"
  cp ${srcPath} ${destPath}
}

function deployGetdownJar {
  srcPath="$1"  
  jarFilename=$(basename ${srcPath})
  targetname=${jarFilename%%.jar}-1.0.jar
  srcDir=$(dirname "${srcPath}")
  srcDir="${CIDS_DISTRIBUTION_DIR}/lib/local${CIDS_EXTENSION}" #TODO remove this line when going live
  src="${srcDir}/${jarFilename}"
  echo " * deploying ${src} => ${APPLIBS}/${targetname}"
  cp "${src}" "${APPLIBS}/${targetname}"
}

#####

function unpackJars {
  TO="$1"; shift
  FROM="$*"
  echo "# unpacking ${FROM} to ${TO}"
  for fromPath in ${FROM}; do 
    if [ -f ${fromPath} ]; then unpackJar "$TO" "${fromPath}"; fi
  done
}

function diffUnpackedJars {
  TO="$1"; shift
  FROM="$*"
  for fromPath in ${FROM}; do 
    if [ -d ${fromPath} ]; then 
        diffUnpackedJar "$TO" "${fromPath}"; 
        if [ $? -ne 0 ]; then
            echo "${fromPath}"
        fi
    fi
  done
}

function buildJars {
  TO="$1"; shift
  FROM="$*"
  echo "# building ${FROM} into ${TO}"
  for fromPath in ${FROM}; do 
    if [ -d ${fromPath} ]; then buildJar "$TO" "${fromPath}"; fi
  done
}

function selfSignJars {
  TO="$1"; shift
  FROM="$*"
  echo "# signing (self signed) ${FROM} into ${TO}"
  for fromPath in ${FROM}; do 
    if [ -f ${fromPath} ]; then selfSignJar "${TO}" "${fromPath}"; fi
  done
}

function clerksterSignJars {
  TO="$1"; shift
  FROM="$*"
  echo "# sending to clerkster (for signing with proper certificate) ${FROM} and writing result into ${TO}"
  for fromPath in ${FROM}; do 
    if [ -f ${fromPath} ]; then clerksterSignJar "${TO}" "$fromPath"; fi
  done
}

function deployFiles {
  TO="$1"; shift
  FROM="$*"
  echo "# deploying ${FROM} to ${TO}"
  if [ ! -d "${TO}" ]; then
    mkdir "${TO}"
  fi
  for fromPath in ${FROM}; do 
    if [ -f ${fromPath} ]; then deployFile "${TO}"/$(basename "${fromPath}") "${fromPath}"; fi
  done
}

function deployGetdownJars {
  FROM="$*"
  echo "# deploying ${FROM} to getdown .libs"
  for fromPath in ${FROM}; do 
    if [ -f ${fromPath} ]; then deployGetdownJar "${fromPath}"; fi
  done 
}

#####

function identifyAppsUsingLibs {
  changedLibs=$*

  echo "### identifying apps that need to be rebuild"

  result=$(for changedLib in ${changedLibs}; do
    grep -l '^code = \.\./\.libs/'$(basename "${changedLib}" | sed 's/\./\\./g')'$' ${APPS}/*/getdown.txt
  done | sort -u | sed 's#/getdown.txt$##g;s#^# * #g')
  if [ -z "${result}" ]; then
    echo " * no rebuild needed"
  else
    echo "${result}"
  fi
}

function rebuildGetdownApps {
  APPLIST=$*;

  echo "### rebuilding getdown starters..."
  if [ ! -z "${APPLIST}" ]; then
    for appDirname in $(ls -1d ${APPLIST}); do 
      echo " * building ${appDirname}"
      java -classpath "${CIDS_DISTRIBUTION_DIR}/lib/m2/com/threerings/getdown/getdown-core/1.8.6/getdown-core-1.8.6.jar" com.threerings.getdown.tools.Digester "${appDirname}" 2> /dev/null
    done
  fi
}

#####

function rebuildChangedResourceJars {
  SOURCE=${1:-${DEFAULT_SOURCE}};
  TARGET=${2:-${DEFAULT_TARGET}};

  echo "### rebuilding changed jars from '${SOURCE}' to '${TARGET}'"

  [ -z "${SOURCE}" -o -z "${TARGET}" ] && echo "SOURCE AND TARGET parameter are mandatory" && exit 1;

  TMP_DIR="${TMP_SESSION_DIR}-rebuildChangedResourceJars"
  UNPACKED="${TMP_DIR}/unpacked"
  UNSIGNED="${TMP_DIR}/unsigned"
  CLERKSTER_SIGNED="${TMP_DIR}/clerkster"
  SELF_SIGNED="${TMP_DIR}/signed"

  echo "### rebuilding changed resource jar"
  mkdir -p "${UNPACKED}"

  unpackJars "${UNPACKED}" "${TARGET}/*.jar"

  echo "# indenfiying changes in ${UNPACKED} with ${SOURCE}"
  diffs="$(diffUnpackedJars "${UNPACKED}" "${SOURCE}"/*)"
  rm -r "${UNPACKED}"

  if [ -z "${diffs}" ]; then
    echo " * no changes found"
  else
    echo "changes found:"
    for diff in $diffs; do
        echo " * ${diff}"
    done
     
    mkdir "${UNSIGNED}" \
    && buildJars "${UNSIGNED}" "${diffs}"

    mkdir "${SELF_SIGNED}" \
    && selfSignJars "${SELF_SIGNED}" "${UNSIGNED}/*.jar" \
    && rm "${UNSIGNED}"/*.jar \
    && rmdir "${UNSIGNED}"

    mkdir "${CLERKSTER_SIGNED}" \
    && clerksterSignJars "${CLERKSTER_SIGNED}" "${SELF_SIGNED}/*.jar" \
    && rm "${SELF_SIGNED}"/*.jar \
    && rmdir "${SELF_SIGNED}"

    deployFiles "${TARGET}" "${CLERKSTER_SIGNED}/*.jar" \
    && rm "${CLERKSTER_SIGNED}"/*.jar \
    && rmdir "${CLERKSTER_SIGNED}"
  fi

  rmdir "${TMP_DIR}"
}

function modifyJnlpStarters {
  [ $# -eq 0 ] && echo "REGEX_REPLACE parameter is mandatory" && exit 1;
  REGEX_REPLACE="$1"; shift

  TMP_DIR="${TMP_SESSION_DIR}-modifyJnlpStarters"
  mkdir -p "${TMP_DIR}"

  CLASSPATH_DIR="${CIDS_DISTRIBUTION_DIR}/lib/classpath${CIDS_EXTENSION}"
  for CLASSPATH_JNLP in $(ls -1 "${CLASSPATH_DIR}"/*-classpath.jnlp); do
    CLASSPATH_TMP="${TMP_DIR}/$(basename ${CLASSPATH_JNLP})"

    #modify classpath jnlp
    sed ${REGEX_REPLACE} "${CLASSPATH_JNLP}" > "${CLASSPATH_TMP}"
  done

  STARTER_DIR="${CIDS_DISTRIBUTION_DIR}/client/${CIDS_EXTENSION}"
  for STARTER_JNLP in $(ls -1 "${STARTER_DIR}"/*-starter.jnlp); do
    STARTER_NAME=$(basename ${STARTER_JNLP})    
    STARTER_TMP="${TMP_DIR}/${STARTER_NAME}"

    #modify starter jnlp
    sed ${REGEX_REPLACE} "${STARTER_JNLP}" > "${STARTER_TMP}" \
    && diff -q "${STARTER_JNLP}" "${STARTER_TMP}" > /dev/null \
    && (
        echo " * no changes detected for ${STARTER_JNLP}" \
        && rm "${STARTER_TMP}" \
    ) && continue;

    # create security jar
    SECURITY_NAME=${STARTER_NAME%%-starter.jnlp}_security
    SECURITY_JAR="${CIDS_DISTRIBUTION_DIR}/client/${CIDS_EXTENSION}/${SECURITY_NAME}.jar"
    SECURITY_TMP="${TMP_DIR}/${SECURITY_NAME}"
    
    ## unpack orig jar to tmp
    unpackJar "${TMP_DIR}" "${SECURITY_JAR}"

    ## remove old certificates
    rm "${SECURITY_TMP}/META-INF/CISMET.SF" "${SECURITY_TMP}/META-INF/CISMET.RSA"
    ## copy extra starter to APPLICATION.JNLP
    cp "${STARTER_TMP}" "${SECURITY_TMP}/JNLP-INF/APPLICATION.JNLP"
    ## pack new jar from tmp
    cd "${SECURITY_TMP}" \
    && zip -qq -r "${SECURITY_TMP}.jar" * \
    && cd --

    rm -r "${SECURITY_TMP}"
  done

  SELF_SIGNED="${TMP_DIR}/selfsigned"  
  mkdir "${SELF_SIGNED}" \
  && selfSignJars "${SELF_SIGNED}" "${TMP_DIR}/*_security.jar" \
  && rm "${TMP_DIR}"/*_security.jar

  CLERKSTER_SIGNED="${TMP_DIR}/clerkstersigned"  
  mkdir "${CLERKSTER_SIGNED}" \
  && clerksterSignJars "${CLERKSTER_SIGNED}" "${SELF_SIGNED}/*_security.jar" \
  && rm "${SELF_SIGNED}"/*_security.jar \
  && rmdir "${SELF_SIGNED}"

  deployFiles "${CLASSPATH_DIR}" "${TMP_DIR}/*-classpath.jnlp" \
  && rm "${TMP_DIR}"/*-classpath.jnlp

  deployFiles "${STARTER_DIR}" "${TMP_DIR}/*-starter.jnlp" \
  && rm "${TMP_DIR}"/*-starter.jnlp

  deployFiles "${STARTER_DIR}" "${CLERKSTER_SIGNED}/*_security.jar" \
  && rm "${CLERKSTER_SIGNED}"/*_security.jar \
  && rmdir "${CLERKSTER_SIGNED}"

  rmdir "${TMP_DIR}"
}

function modifyGetDownStarters {
  [ $# -eq 0 ] && echo "REGEX_REPLACE parameter is mandatory" && exit 1;
  REGEX_REPLACE="$1"; shift

  APPS_DIR="${CIDS_DISTRIBUTION_DIR}/apps"  
  TMP_DIR="${TMP_SESSION_DIR}-modifyGetDownStarters"  
  mkdir -p "${TMP_DIR}"\
  && if [ -d "${APPS_DIR}" ]; then
    APPS_TMP="${TMP_DIR}/apps"
    mkdir -p "${APPS_TMP}"

    for GETDOWN_TXT in $(ls -1 "${APPS_DIR}"/*/getdown.txt); do
      APP_DIR=${GETDOWN_TXT%%/getdown.txt}
      APP_NAME=$(basename "${APP_DIR}")
      GETDOWN_TMP="${APPS_TMP}/${APP_NAME}.txt"
      sed ${REGEX_REPLACE} "${GETDOWN_TXT}" > "${GETDOWN_TMP}"
    done

    for GETDOWN_TMP in $(ls -1 "${APPS_TMP}"/*.txt); do
      APP_NAME=$(basename "${GETDOWN_TMP%%.txt}")
      GETDOWN_TXT="${APPS_DIR}/${APP_NAME}/getdown.txt"
      diff -q "${GETDOWN_TXT}" "${GETDOWN_TMP}" > /dev/null \
      && (
        echo " * no changes detected for ${GETDOWN_TXT}") \
        || (deployFile "${GETDOWN_TXT}" "${GETDOWN_TMP}"\
      ) && rm "${GETDOWN_TMP}"
    done

    rmdir "${APPS_TMP}"
  fi \
  && rmdir "${TMP_DIR}"
}

### LOCAL_CTL ###

COMMAND="$1"; shift

case "$COMMAND" in

  modifyStarters)
    REGEX_REPLACE=$1; shift

    modifyJnlpStarters $REGEX_REPLACE
    modifyGetDownStarters $REGEX_REPLACE
    rebuildGetdownApps ${APPS}/*
  ;;

  deployChanged)
    SOURCE=${1:-${DEFAULT_SOURCE}}; shift
    TARGET=${1:-${DEFAULT_TARGET}}; shift

    rebuildOutput=$(rebuildChangedResourceJars "${SOURCE}" "${TARGET}")
    echo "${rebuildOutput}"

    deployedJars=$(echo "${rebuildOutput}" | grep '^ \* deploying .*' | sed 's#^.* => ##g')

    if [ ! -z "${deployedJars}" ]; then
      deployedLibsOutput=$(deployGetdownJars ${deployedJars})
      echo "${deployedLibsOutput}"
      deployedLibs=$(echo "${deployedLibsOutput}" | grep '^ \* deploying .*' | sed 's#^.* => ##g')
    fi

    if [ ! -z "${deployedLibs}" ]; then
      appsToRebuildOutput=$(identifyAppsUsingLibs "$deployedLibs")
      echo "${appsToRebuildOutput}"
      appsToRebuild=$(echo "${appsToRebuildOutput}" | grep -v '^ \* no rebuild needed' | grep '^ \*' | awk '{print $2}')
    fi

    if [ ! -z "${appsToRebuild}" ]; then
      rebuildGetdownApps ${appsToRebuild}
    fi
  ;;  

  init)
    SOURCE=${1:-${DEFAULT_SOURCE}}; shift
    TARGET=${1:-${DEFAULT_TARGET}}; shift

    if [ ! -z "${SOURCE}" -a -d "${SOURCE}" ]; then
      if [ ! -z "${CLIENT_RESOURCES_OVERWRITE}" -a -d "${CLIENT_RESOURCES_OVERWRITE}" ]; then
        cp -r "${CLIENT_RESOURCES_OVERWRITE}"/* "${SOURCE}"/
      fi
    
      rebuildChangedResourceJars "${SOURCE}" "${TARGET}"
    fi
    if [ ! -z "${CIDSDISTRIBUTION_HOST}" ]; then
      REGEX_REPLACE='s#'$(echo ${CIDS_CODEBASE} | sed 's/[.[\*^$]/\\&/g')'#'${CIDSDISTRIBUTION_HOST}'#g'
      modifyJnlpStarters $REGEX_REPLACE
      modifyGetDownStarters $REGEX_REPLACE
    fi
    deployGetdownJars "${TARGET}/*.jar"
    rebuildGetdownApps ${APPS}/*
  ;;

  *)
    echo "Usage: $0 init [source_dir] [target_dir]|deployChanged [source_dir] [target_dir]|modifyStarters"
  ;;

esac
