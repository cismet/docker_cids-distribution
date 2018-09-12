#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:6.4-debian

#----

docker build \
  -t ${IMAGE} \
  .
