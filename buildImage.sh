#!/bin/bash
IMAGE_VERSION=6.1-debian

#----

IMAGE_NAME=reg.cismet.de/abstract/cids-distribution

docker build \
  --build-arg IMAGE_VERSION=${IMAGE_VERSION} \
  -t ${IMAGE_NAME}:${IMAGE_VERSION} \
  .
