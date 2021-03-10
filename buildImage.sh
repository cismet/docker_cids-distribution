#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:6.7-debian

#----

docker build \
  -t ${IMAGE} \
  .
