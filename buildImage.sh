#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:7.2.1-debian

#----

docker build \
  -t ${IMAGE} \
  .
