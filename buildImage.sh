#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:7.2-debian

#----

docker build \
  -t ${IMAGE} \
  .
