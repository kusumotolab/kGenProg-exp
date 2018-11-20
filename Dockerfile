FROM openjdk:8

RUN set -ex \
        && apt-get update

RUN set -ex \
        && apt-get install -y \
        git \
        gradle \
        maven \
        vim \
        libdbi-perl # for d4j

WORKDIR /root/

RUN set -ex \
        && echo 'source util.sh; ' > .bash_history
