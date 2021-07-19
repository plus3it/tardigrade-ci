FROM golang:1.16.6-buster as golang

FROM python:3.9.6-buster

ARG PROJECT_NAME=tardigrade-ci
ARG GITHUB_ACCESS_TOKEN
ENV PATH="/root/.local/bin:/root/bin:/go/bin:/usr/local/go/bin:${PATH}"
ENV GOPATH=/go
COPY --from=golang /go/ /go/
COPY --from=golang /usr/local/go/ /usr/local/go/
COPY . /${PROJECT_NAME}
RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
    jq \
    unzip \
    make \
    && make -C /${PROJECT_NAME} install \
    && touch /.dockerenv \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["make"]
