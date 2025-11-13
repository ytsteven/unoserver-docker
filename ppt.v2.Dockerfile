# Use the Ubuntu-based image
# FROM alpine:3.18.3
FROM hongyaa-docker.pkg.coding.net/qingjiao/service-pub/ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list && \
    sed -i "s/security.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list && \
    apt -y update && \
    apt -y install curl cron tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata

ADD "https://hongyaa-generic.pkg.coding.net/qingjiao/tools/env2file-linux?version=0.1.3" /usr/local/bin/env2file
RUN chmod 755 /usr/local/bin/env2file
RUN mkdir -p /opt/qingjiao-service/
WORKDIR /opt/qingjiao-service

ARG BUILD_CONTEXT="build-context"
ARG UID=worker
ARG GID=worker
# renovate: pypi: unoserver
ARG VERSION_UNOSERVER=3.4

LABEL org.opencontainers.image.title="unoserver-docker"
LABEL org.opencontainers.image.description="Container image that contains unoserver and libreoffice including large set of fonts for file format conversions"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.documentation="https://github.com/unoconv/unoserver-docker/blob/main/README.adoc"
LABEL org.opencontainers.image.source="https://github.com/unoconv/unoserver-docker"
LABEL org.opencontainers.image.url="https://github.com/unoconv/unoserver-docker"

WORKDIR /

# RUN addgroup -S ${GID} && adduser -S ${UID} -G ${GID}
RUN addgroup --system ${GID} && adduser --system ${UID} --ingroup ${GID}

# RUN apk add --no-cache \
#     bash curl \
#     py3-pip \
#     libreoffice \
#     supervisor

# # fonts - https://wiki.alpinelinux.org/wiki/Fonts
# RUN apk add --no-cache \
#     font-noto font-noto-cjk font-noto-extra \
#     terminus-font \
#     ttf-font-awesome \
#     ttf-dejavu \
#     ttf-freefont \
#     ttf-hack \
#     ttf-inconsolata \
#     ttf-liberation \
#     ttf-mononoki  \
#     ttf-opensans   \
#     fontconfig && \
#     fc-cache -f

# RUN rm -rf /var/cache/apk/* /tmp/*
# Install packages on Ubuntu
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    # curl \
    wget \
    apt-transport-https \
    net-tools \
    vim \
    python3-pip \
    libreoffice \
    supervisor \
    poppler-utils

# Fonts - Install fonts packages on Ubuntu
RUN apt-get install -y --no-install-recommends \
    fonts-noto-cjk \
    xfonts-terminus \
    fonts-font-awesome \
    fonts-dejavu \
    fonts-freefont-ttf \
    fonts-hack \
    fonts-inconsolata \
    fonts-liberation \
    fonts-mononoki \
#    fonts-opensans \
    fontconfig && \
    fc-cache -f

# Cleanup
RUN rm -rf /var/lib/apt/lists/* && apt-get clean

# https://github.com/unoconv/unoserver/
RUN pip install --break-system-packages -U unoserver==${VERSION_UNOSERVER}

# setup supervisor
COPY --chown=${UID}:${GID} ${BUILD_CONTEXT} /
RUN chmod +x entrypoint.sh && \
    #    mkdir -p /var/log/supervisor && \
    #    chown ${UID}:${GID} /var/log/supervisor && \
    #    mkdir -p /var/run && \
    chown -R ${UID}:0 /run && \
    chmod -R g=u /run

USER ${UID}
WORKDIR /home/worker
ENV HOME="/home/worker"

VOLUME ["/data"]
EXPOSE 2003
ENTRYPOINT ["/entrypoint.sh"]
