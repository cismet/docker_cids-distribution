#!bin/bash

if [ -f "${EXEC_BEFORE_START}" ]; then
  echo "\e[32mINFO\e[39m: executing ${EXEC_BEFORE_START}"
  ${EXEC_BEFORE_START} || exit 1;
fi

echo "\e[32mINFO\e[39m: starting gitlab-runner"
/usr/local/bin/gitlab-runner run --user=root --working-directory=/gitlab-runner