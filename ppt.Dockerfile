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
RUN mkdir -p /opt/region/
WORKDIR /opt/qingjiao-service

# build unoserver-docker env
ARG BUILD_CONTEXT="build-context"
ARG UID=worker
ARG GID=worker

LABEL org.opencontainers.image.title="unoserver-docker"
LABEL org.opencontainers.image.description="Custom Docker Image that contains unoserver, LibreOffice, and major sets of fonts for file format conversions"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.documentation="https://github.com/unoconv/unoserver-docker/blob/master/README.md"
LABEL org.opencontainers.image.source="https://github.com/unoconv/unoserver-docker"
LABEL org.opencontainers.image.url="https://github.com/unoconv/unoserver-docker"

# Install required packages
RUN addgroup --system ${GID} && adduser --system ${UID} --ingroup ${GID}

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

# Renovate: Add the logic for installing JDK as needed
# renovate: datasource=repology depName=temurin-17-jdk versioning=loose
# ARG VERSION_ADOPTIUM_TEMURIN="17.0.7_p7-r0"

# install Eclipse Temurin JDK
RUN mkdir -p /etc/apt/keyrings 2>/dev/null
RUN wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public >> /etc/apt/keyrings/adoptium.asc 
RUN echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://mirrors.tuna.tsinghua.edu.cn/Adoptium/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" >> /etc/apt/sources.list.d/adoptium.list
RUN apt-get install temurin-17-jdk

# Install unoserver
RUN pip3 install -U unoserver

# Set up Supervisor
COPY --chown=${UID}:${GID} ${BUILD_CONTEXT}/supervisor /
RUN chmod +x /config/entrypoint.sh && \
#    mkdir -p /var/log/supervisor && \
#    chown ${UID}:${GID} /var/log/supervisor && \
#    mkdir -p /var/run && \
    chown -R ${UID}:0 /run && \
    chmod -R g=u /run

# USER ${UID}
# USER root
# WORKDIR /home/worker
# ENV HOME="/home/worker"

VOLUME ["/data"]

ENTRYPOINT ["/config/entrypoint.sh"]
