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
       -v /etc/localtime:/etc/localtime:ro \
       -v /opt/apr-data:/opt/apr-data \
       -v ${PWD}/util.sh:/root/util.sh \
       -e APR=$APR \
       -e SEED=$SEED \
       apr-exp \
       /bin/bash

#       --cpuset-cpus=0
