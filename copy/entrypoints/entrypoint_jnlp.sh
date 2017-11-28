#!/bin/sh

echo -e "\e[32mINFO\e[39m: starting nginx"
sed -i -- "s#__CIDS_DISTRIBUTION_DIR__#${CIDS_DISTRIBUTION_DIR:-/cidsDistribution}#g" /etc/nginx/sites-available/default

nginx -g 'daemon off;'
