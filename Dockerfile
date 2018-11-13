FROM openjdk:8

RUN set -ex \
        && apt-get update

RUN set -ex \
        && apt-get install -y \
        git \
        gradle \
        maven


WORKDIR /apr-exp
RUN mkdir -p script/

COPY init-astor.sh ./script/
RUN set -ex \
        && bash script/init-astor.sh

COPY init-d4j.sh ./script/
RUN set -ex \
        && bash script/init-d4j.sh


COPY checkout-math.sh ./script/
RUN set -ex \
        && bash script/checkout-math.sh

COPY fix-surefire-bug.sh ./script/
RUN set -ex \
	&& bash script/fix-surefire-bug.sh

COPY mvn-compile.sh ./script/
RUN set -ex \
	&& bash script/mvn-compile.sh



COPY init-kgp.sh script/
RUN set -ex \
        && bash script/init-kgp.sh

RUN set -ex \
        && apt-get install -y \
        vim
COPY *.sh ./script/
