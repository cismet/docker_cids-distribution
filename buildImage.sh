#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:6.3.4-debian

#----

docker build \
  -t ${IMAGE} \
  .
