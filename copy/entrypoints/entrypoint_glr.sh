#!/bin/bash

if [ ! -z "${EXEC_BEFORE_START}" ]; then
  echo -e "\e[32mINFO\e[39m: executing ${EXEC_BEFORE_START}"
  bash -c "${EXEC_BEFORE_START}" || exit 1;
fi

if [ -z "${GLR_TOKEN}" ]; then
  echo "GLR_TOKEN not set. You can generate one by registering the runner."
else
  /usr/local/bin/gitlab-runner list 2>&1 | grep "${GLR_TOKEN}"
  [ $? -eq 0 ] || echo "GLR_TOKEN ${GLR_TOKEN} not found in config" && exit 2;
fi

echo -e "\e[32mINFO\e[39m: starting gitlab-runner"
/usr/local/bin/gitlab-runner run --user=root --working-directory=/gitlab-runner