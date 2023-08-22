#!/bin/bash

# external variables:
#  CLIENT_CONFIGS_SOURCE       (where are the sources)
#  CLIENT_CONFIGS_TARGET       (where should the files be copied/rewritten into)
#  {FILE}_CFG_PROPERTY_{KEY}   (key/value pairs to append to specific config files)
#  CFG_TEMPLATE_PROPERTY_{KEY} (template replacement entries)
#  CIDS_DISTRIBUTION_DIR       (comes from the distribution project, almost certainly set to '/cidsDistribution')
#  CIDS_EXTENSION              (comes from the distribution project, probably 'WuNDa', 'WRRLDBMV' or something like that)

if [ ! -z "${CLIENT_CONFIGS_SOURCE}" ]; then
  SOURCE=${CLIENT_CONFIGS_SOURCE}
else
  SOURCE="${GIT_TARGET_configs}"
fi

if [ ! -z "${CLIENT_CONFIGS_TARGET}" ]; then
  TARGET=${CLIENT_CONFIGS_TARGET}
else
  TARGET="${CIDS_DISTRIBUTION_DIR}/client"
fi

if [ ! -z "${SOURCE}" ]; then
  for SOURCE_ENTRY in "${SOURCE}"/*; do
    cp -r "${SOURCE_ENTRY}" "${TARGET}"
  done
fi

CFG_REGEX="^(.*)_CFG_PROPERTY_(.*)=(.*)$"
CFG_FILE_MATCH="\\1"
CFG_KEY_MATCH="\\2"
CFG_VALUE_MATCH="\\3"

declare -A APPEND_CFGS
declare -a APPEND_FILES
APPEND_FILES+="*"
for ENV_CFG in $(env | grep -E "${CFG_REGEX}"); do
    CFG_FILE=("$(echo "${ENV_CFG}" | sed -E 's#'"${CFG_REGEX}"'#'"${CFG_FILE_MATCH}"'#')")    
    CFG_KEY=("$(echo "${ENV_CFG}" | sed -E 's#'"${CFG_REGEX}"'#'"${CFG_KEY_MATCH}"'#')")
    CFG_VALUE=("$(echo "${ENV_CFG}" | sed -E 's#'"${CFG_REGEX}"'#'"${CFG_VALUE_MATCH}"'#')")

    APPEND_CFG="${CFG_KEY}=${CFG_VALUE}\n"

    [ -z "${CFG_FILE}" ] && APPEND_FILE="*" || APPEND_FILE="${CFG_FILE}"
    APPEND_CFGS+=([${APPEND_FILE}]+=${APPEND_CFG})
    [[ ${APPEND_FILES[*]} =~ "${APPEND_FILE}" ]] || APPEND_FILES+=("${APPEND_FILE}")
done

CLIENT_CONFIGS="${TARGET}/${CIDS_EXTENSION}/config"

for APPEND_FILE in "${APPEND_FILES[@]}"; do 
    [ "${APPEND_FILE}" != '*' ] && touch "${CLIENT_CONFIGS}/${APPEND_FILE}.cfg"
done

for APPEND_FILE in "${APPEND_FILES[@]}"; do 
    FILES="${CLIENT_CONFIGS}/${APPEND_FILE}.cfg"
    for FILE in ${FILES}; do
        APPEND_CFG=${APPEND_CFGS[$APPEND_FILE]}
        if [ ! -z "${APPEND_CFG}" ]; then
            echo -e "${APPEND_CFG}" >> "${FILE}"
        fi
    done
done

TEMPLATE_REGEX="^CFG_TEMPLATE_PROPERTY_(.*)=(.*)$"
TEMPLATE_KEY_MATCH="\\1"
TEMPLATE_VALUE_MATCH="\\2"

for ENV_TEMPLATE in $(env | grep -E "${TEMPLATE_REGEX}"); do
    TEMPLATE_KEY=("$(echo "${ENV_TEMPLATE}" | sed -E 's#'"${TEMPLATE_REGEX}"'#'"${TEMPLATE_KEY_MATCH}"'#')")
    TEMPLATE_VALUE=("$(echo "${ENV_TEMPLATE}" | sed -E 's#'"${TEMPLATE_REGEX}"'#'"${TEMPLATE_VALUE_MATCH}"'#')")
    for TEMPLATE_FILE in "${CLIENT_CONFIGS}"/*.cfg; do
        sed -i -E 's#\$\{'"${TEMPLATE_KEY}"'\}#'${TEMPLATE_VALUE}'#g' "${TEMPLATE_FILE}"
    done
done