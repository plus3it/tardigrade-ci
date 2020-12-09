FROM golang:1.15.6-buster as golang
FROM python:3.9.1-buster
ENV PATH="/root/.local/bin:/root/bin:/go/bin:/usr/local/go/bin:${PATH}"
ENV GOPATH=/go
RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
    jq \
    unzip \
    make \
&& rm -rf /var/lib/apt/lists/*
COPY --from=golang /go/ /go/
COPY --from=golang /usr/local/go/ /usr/local/go/
COPY . /ci-harness
RUN cd /ci-harness && make install
WORKDIR /ci-harness
ENTRYPOINT ["make"]
