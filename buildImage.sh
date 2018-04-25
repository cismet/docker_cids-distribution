#!/bin/bash

IMAGE=reg.cismet.de/abstract/cids-distribution:6.3.2-debian

#----

docker build \
  -t ${IMAGE} \
  .
