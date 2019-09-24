#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:6.5-debian

#----

docker build \
  -t ${IMAGE} \
  .
