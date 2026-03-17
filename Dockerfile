# syntax=docker/dockerfile:1

FROM golang:1.26-bookworm AS golang

FROM debian:bookworm-slim@sha256:f06537653ac770703bc45b4b113475bd402f451e85223f0f2837acbf89ab020a

ARG PROJECT_NAME=tardigrade-ci

ENV USER=${PROJECT_NAME}

# Things to do as root
USER root

RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
    git \
    jq \
    unzip \
    make \
    vim \
    build-essential \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    llvm \
    libncursesw5-dev \
    tk-dev \
    libxml2-dev \
    libxmlsec1-dev \
    libffi-dev \
    liblzma-dev \
    && touch /.dockerenv \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos '' ${USER}

COPY --from=golang /usr/local/go/ /usr/local/go/
COPY --chown=${USER}:${USER} --from=golang /go/ /go/
COPY --chown=${USER}:${USER} . /${PROJECT_NAME}
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Things to do as $USER
USER ${USER}

ENV HOME="/home/${USER}"
ENV VIRTUAL_ENV=${HOME}/.venv
ENV PATH="${VIRTUAL_ENV}/bin:${HOME}/.local/bin:${HOME}/bin:/go/bin:/usr/local/go/bin:${PATH}"

ENV GOPATH=/go
ENV TF_PLUGIN_CACHE_DIR=${HOME}/.terraform.d/plugin-cache

RUN mkdir -p "$TF_PLUGIN_CACHE_DIR"

RUN --mount=type=secret,id=GITHUB_ACCESS_TOKEN \
    GITHUB_ACCESS_TOKEN="$(cat /run/secrets/GITHUB_ACCESS_TOKEN)" \
    make -C /${PROJECT_NAME} install/docker

RUN python --version \
    && python3 --version \
    && python3.12 --version

WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["entrypoint.sh"]
