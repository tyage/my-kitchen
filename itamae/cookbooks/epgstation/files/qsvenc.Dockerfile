FROM l3tnun/epgstation:master-debian as upstream
FROM node:20-slim as node

FROM ubuntu:22.04

RUN apt update && \
    apt install -y gpg-agent wget 

# Install intel graphics driver
RUN wget -qO - https://repositories.intel.com/graphics/intel-graphics.key | \
        gpg --dearmor --output /usr/share/keyrings/intel-graphics.gpg && \
    echo 'deb [arch=amd64,i386 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/graphics/ubuntu jammy arc' | \
        tee  /etc/apt/sources.list.d/intel.gpu.jammy.list && \
    apt update && \
    apt install -y intel-media-va-driver-non-free intel-opencl-icd

# Install qsvencc
RUN wget -q https://github.com/rigaya/QSVEnc/releases/download/7.57/qsvencc_7.57_Ubuntu22.04_amd64.deb -O /tmp/qsvencc.deb && \
    apt install -y /tmp/qsvencc.deb

COPY --from=upstream /app /app/

# Copy node files from slim image because node.js in ubuntu 22.04 is too old
# ref. https://zenn.dev/jrsyo/articles/e42de409e62f5d
COPY --from=node /usr/local/include/ /usr/local/include/
COPY --from=node /usr/local/lib/ /usr/local/lib/
COPY --from=node /usr/local/bin/ /usr/local/bin/
# reset symlinks
RUN corepack disable && corepack enable

# Copy from epgstation/debian.Dockerfile
ENV DEV="make gcc git g++ automake curl wget autoconf build-essential libass-dev libfreetype6-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev"
ENV FFMPEG_VERSION=6.1

RUN apt-get update && \
    apt-get -y install $DEV && \
    apt-get -y install yasm libx264-dev libmp3lame-dev libopus-dev libvpx-dev && \
    apt-get -y install libx265-dev libnuma-dev && \
    apt-get -y install libasound2 libass9 libvdpau1 libva-x11-2 libva-drm2 libxcb-shm0 libxcb-xfixes0 libxcb-shape0 libvorbisenc2 libtheora0 libaribb24-dev && \
    apt-get -y install libva-dev libvpl-dev && \
\
#ffmpeg build
    mkdir /tmp/ffmpeg_sources && \
    cd /tmp/ffmpeg_sources && \
    curl -fsSL http://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.bz2 | tar -xj --strip-components=1 && \
    ./configure \
      --prefix=/usr/local \
      --disable-shared \
      --pkg-config-flags=--static \
      --enable-gpl \
      --enable-libass \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-libtheora \
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
ENTRYPOINT ["npm"]
CMD ["start"]