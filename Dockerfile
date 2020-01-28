FROM golang:1.13.6-buster
ENV PATH="/root/.local/bin:/root/bin:${PATH}"
RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
    jq \
    unzip \
    make \
    python3.7 \
    python3-pip \
&& rm -rf /var/lib/apt/lists/*
COPY . /ci-harness
RUN cd /ci-harness && make install
WORKDIR /ci-harness
ENTRYPOINT ["make"]
