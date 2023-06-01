#!/bin/bash

if [ ! -z "${GIT_TARGET_configs}" ]; then
  for GIT_TARGET_config in "${GIT_TARGET_configs}"/*; do
    cp -r "${GIT_TARGET_config}" "${CIDS_DISTRIBUTION_DIR:-/cidsDistribution}/client/"
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