#!/bin/bash

mkdir -p /opt/apr-data
mkdir -p tmp

chmod +x util.sh

docker build \
       -t apr-exp \
       -f Dockerfile \
       tmp/

docker run \
       --rm \
       --interactive \
       --tty \
       -v /opt/apr-data:/opt/apr-data \
       -v ${PWD}/util.sh:/root/util.sh \
       apr-exp \
       /bin/bash
