#!/bin/bash

KEYS_REGEX="^GIT_ORIGIN_(.*)=.*$"
KEYS_MATCH="\\1"
export GIT_ORIGIN__=${GIT_ORIGIN}

KEYS=()
if [ $# -gt 0 ]; then
  KEYS+=("$*")
else
  for ENV_GIT_ORIGIN in $(env | grep -E "$KEYS_REGEX"); do
    KEYS+=("$(echo "${ENV_GIT_ORIGIN}" | sed -E 's#'"$KEYS_REGEX"'#'"$KEYS_MATCH"'#')")
  done
fi

for KEY in ${KEYS[@]}; do
  GIT_ORIGIN_VAR=GIT_ORIGIN_$KEY
  GIT_TARGET_VAR=GIT_TARGET_$KEY
  GIT_BRANCH_VAR=GIT_BRANCH_$KEY

  GIT_ORIGIN_VALUE=${!GIT_ORIGIN_VAR:-${GIT_ORIGIN}}
  GIT_BRANCH_VALUE=${!GIT_BRANCH_VAR:-${GIT_BRANCH}}
  GIT_TARGET_VALUE=${!GIT_TARGET_VAR:-${GIT_TARGET}}

  [[ -z "${GIT_ORIGIN_VALUE}" ]] && continue
  
  # checking necessary variables
  [[ -z "${GIT_BRANCH_VALUE}" ]] && echo "environment variable GIT_BRANCH or ${GIT_BRANCH_VAR} is missing" && exit 11
  [[ -z "${GIT_TARGET_VALUE}" ]] && echo "environment variable GIT_TARGET or ${GIT_TARGET_VAR} is missing" && exit 12

  # creating target directory if necessary and cd into it
  [[ -d "${GIT_TARGET_VALUE}" ]] || mkdir -p "${GIT_TARGET_VALUE}" && cd ${GIT_TARGET_VALUE} || exit 20
  # creating local git repo if necessary
  [[ -d .git ]] || ( git init && git remote add origin ${GIT_ORIGIN_VALUE} ) || exit 30
  # pulling branch from origin
  git fetch origin ${GIT_BRANCH_VALUE} && git checkout ${GIT_BRANCH_VALUE} && git pull || exit 40
done
