FROM l3tnun/epgstation:v2.10.0-debian AS upstream

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
RUN wget -q https://github.com/rigaya/QSVEnc/releases/download/8.30/qsvencc_8.30_amd64.deb -O /tmp/qsvencc.deb && \
    apt-get update && \
    apt-get install -y /tmp/qsvencc.deb

COPY --from=upstream /app /app/
COPY docker-entrypoint.sh /usr/local/bin/my-kitchen-epgstation-entrypoint
RUN chmod 0755 /usr/local/bin/my-kitchen-epgstation-entrypoint

RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg

# Refresh packages inherited from cached base and build layers.
RUN apt-get update && apt-get upgrade -y

EXPOSE 8888
WORKDIR /app
ENTRYPOINT ["/usr/local/bin/my-kitchen-epgstation-entrypoint"]
CMD ["npm", "start"]
