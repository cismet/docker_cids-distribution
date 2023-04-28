#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:8.0-debian

#----

docker build \
  -t ${IMAGE} \
  .
