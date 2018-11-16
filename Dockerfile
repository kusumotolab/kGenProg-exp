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


# ENV PATH=$PATH:/root/

# use defined functions for apr as init-file
# COPY util.sh /root/.bashrc


#RUN mkdir script/
#SHELL ["/bin/bash", "-c"]
#RUN ["source", "util.sh"]
#RUN ["/bin/bash", "--login", "-c", "source util.sh"]

#CMD ["ls", "-la", "."]
#CMD ["/bin/bash", "-c", "source script/util.sh"]
# CMD [".", "script/util.sh"]

#
# COPY init-astor.sh ./script/
# RUN set -ex \
#         && bash script/init-astor.sh
#
# COPY init-d4j.sh ./script/
# RUN set -ex \
#         && bash script/init-d4j.sh
#
#
# COPY checkout-math.sh ./script/
# RUN set -ex \
#         && bash script/checkout-math.sh
#
# COPY fix-surefire-bug.sh ./script/
# RUN set -ex \
# 	&& bash script/fix-surefire-bug.sh
#
# COPY mvn-compile.sh ./script/
# RUN set -ex \
# 	&& bash script/mvn-compile.sh
#
#
#
# COPY init-kgp.sh script/
# RUN set -ex \
#         && bash script/init-kgp.sh
#
# RUN set -ex \
#         && apt-get install -y \
#         vim
# COPY *.sh ./script/
#
