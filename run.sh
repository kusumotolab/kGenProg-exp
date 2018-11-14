#!/bin/bash

mkdir -p /opt/apr-data

docker build \
       -t apr-exp \
       -f Dockerfile \
       script/

docker run \
       --rm \
       --interactive \
       --tty \
       -v /opt/apr-data:/opt/apr-data \
       --name $1 \
       apr-exp \
       /bin/bash

#       /bin/bash -c 'echo a' -i

#       /bin/bash --init-file <(echo "util.sh")
