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
       -v ${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa \
       -e APR=$APR \
       -e SEED=$SEED \
       apr-exp \
       /bin/bash
#       --cpuset-cpus=0
