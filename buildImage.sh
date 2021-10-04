#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:7.0.1-debian

#----

docker build \
  -t ${IMAGE} \
  .
