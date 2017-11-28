#!/bin/bash

find -L ${MAVEN_LIB_DIR} -name *.jar -type f -newermm ${MAVEN_LIB_DIR}/.signed
