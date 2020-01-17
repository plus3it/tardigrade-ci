FROM golang:1.13.4-buster
RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
    jq \
    unzip \
    make \
&& rm -rf /var/lib/apt/lists/*
COPY . /ci-harness
RUN cd /ci-harness && make install
ENV PATH="/root/bin:${PATH}"
WORKDIR /ci-harness
ENTRYPOINT ["make"]
