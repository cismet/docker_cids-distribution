#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:6.3.1-debian

#----

docker build \
  -t ${IMAGE} \
  .
