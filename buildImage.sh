#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:6.6-debian

#----

docker build \
  -t ${IMAGE} \
  .
