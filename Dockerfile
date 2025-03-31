# Note - do not remove the ##telegraf## tags from this file - they are used to build a tag that includes the telegraf binary
##telegraf##FROM telegraf:1.26 AS telegraf

##telegraf##RUN touch /tmp/emptyfile

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:mlatclient AS buildimage

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN \
    apt-get update -q -y && \
    apt-get install -o Dpkg::Options::="--force-confnew" -y --no-install-recommends -q \
    libssl-dev && \
    folder="stunnel-5.74" && \
    archive="${folder}.tar.gz" && \
    wget "https://www.stunnel.org/downloads/archive/5.x/$archive" && \
    tar xf "$archive" && \
    pushd "$folder" && \
    ./configure --prefix=/usr \
        --sysconfdir=/etc \
        --localstatedir=/var \
        --disable-systemd && \
    make -j4 && \
    cp src/stunnel /


FROM ghcr.io/sdr-enthusiasts/docker-baseimage:wreadsb

ENV BEASTPORT=30005 \
    SMUSERNAME=yourusername \
    SMPASSWORD=yourpassword \
    MLAT=false

SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN \
    --mount=type=bind,from=buildimage,source=/,target=/buildimage/ \
    cp -v /buildimage/stunnel /usr/bin && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    KEPT_PACKAGES+=(gzip) && \
    KEPT_PACKAGES+=(curl) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-suggests --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}" && \
    # Clean-up.
    apt-get autoremove -q -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0 -y "${TEMP_PACKAGES[@]}" && \
    apt-get clean -q -y && \
    bash /scripts/clean-build.sh && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* /var/cache/*

COPY rootfs/ /
