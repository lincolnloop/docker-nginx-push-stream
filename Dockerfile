FROM ubuntu:14.04

ENV NGINX_VERSION 1.6.3
ENV PSM_VERSION 0.4.1

RUN apt-get update && apt-get install -y python wget software-properties-common

RUN add-apt-repository -y -s ppa:nginx/stable && apt-get update && \
    apt-get build-dep -y nginx && \
    apt-get source -y nginx=${NGINX_VERSION}

WORKDIR /nginx-${NGINX_VERSION}

RUN mv debian/rules  debian/rules.orig && \
    awk '/\t\t\t--add-module=\$\(MODULESDIR\)\/nginx-upstream-fair/ { print; print "\t\t\t--add-module=$(MODULESDIR)/nginx-push-stream-module \\"; next }1' debian/rules.orig > debian/rules

RUN wget -q https://github.com/wandenberg/nginx-push-stream-module/archive/${PSM_VERSION}.tar.gz && \
    tar xzf ${PSM_VERSION}.tar.gz && \
    ln -s ../../nginx-push-stream-module-${PSM_VERSION} debian/modules/nginx-push-stream-module

RUN dpkg-buildpackage -uc -b -j4 && \
    mkdir /dist && mv /nginx*.deb /dist && cd /dist && \
    md5sum nginx*.deb | tee nginx.md5
    
RUN wget -qO- https://bootstrap.pypa.io/get-pip.py | python -
RUN pip install awscli

CMD aws s3 sync --acl=public-read /dist/ s3://${S3_BUCKET}/


