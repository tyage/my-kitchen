FROM l3tnun/epgstation:master-debian as upstream

FROM ubuntu:24.04

RUN apt update && \
    apt install -y gnupg wget software-properties-common curl

# Install node.js 24
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs

# Install intel graphics driver
RUN add-apt-repository multiverse && \
    apt update && \
    apt install -y intel-media-va-driver-non-free intel-opencl-icd

RUN wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg && \
    echo "deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu noble unified" | \
    tee /etc/apt/sources.list.d/intel-gpu-noble.list && \
    apt update

# Install qsvencc
RUN wget -q https://github.com/rigaya/QSVEnc/releases/download/8.11/qsvencc_8.11_amd64.deb -O /tmp/qsvencc.deb && \
    apt install -y /tmp/qsvencc.deb

COPY --from=upstream /app /app/
COPY docker-entrypoint.sh /usr/local/bin/my-kitchen-epgstation-entrypoint
RUN chmod 0755 /usr/local/bin/my-kitchen-epgstation-entrypoint

# Install build tools
ENV DEV="make gcc git g++ automake curl wget autoconf build-essential libass-dev libfreetype6-dev libtool libva-dev libvorbis-dev pkg-config zlib1g-dev nasm"
ENV FFMPEG_VERSION=8.1.1

RUN apt-get update && \
    apt-get -y install $DEV && \
    apt-get -y install yasm libx264-dev libmp3lame-dev libopus-dev libvpx-dev && \
    apt-get -y install libx265-dev libnuma-dev && \
    apt-get -y install libasound2t64 libass9 libva-x11-2 libva-drm2 libvorbisenc2 libaribb24-dev && \
    apt-get -y install libva-dev libvpl-dev

# Build ffmpeg
RUN mkdir /tmp/ffmpeg_sources && \
    cd /tmp/ffmpeg_sources && \
    curl -fsSL https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 | tar -xj --strip-components=1 && \
    ./configure \
      --prefix=/usr/local \
      --disable-shared \
      --pkg-config-flags=--static \
      --enable-gpl \
      --enable-libass \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libx264 \
      --enable-libx265 \
      --enable-version3 \
      --enable-libaribb24 \
      --enable-nonfree \
      --disable-debug \
      --disable-doc \
      --enable-libvpl \
      --enable-vaapi \
    && \
    make -j$(nproc) && \
    make install

EXPOSE 8888
WORKDIR /app
ENTRYPOINT ["/usr/local/bin/my-kitchen-epgstation-entrypoint"]
