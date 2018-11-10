FROM openjdk:8

RUN set -ex \
        && apt-get update

RUN set -ex \
        && apt-get install -y \
        git \
        gradle \
        maven


WORKDIR /apr-exp

COPY init-kgp.sh ./
RUN set -ex \
        && bash init-kgp.sh

COPY init-astor.sh ./
RUN set -ex \
        && bash init-astor.sh

COPY init-d4j.sh ./
RUN set -ex \
        && bash init-d4j.sh

COPY checkout-math.sh ./
RUN set -ex \
        && bash checkout-math.sh
