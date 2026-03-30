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
    && touch /.dockerenv \
    && rm -rf /var/lib/apt/lists/*

RUN addgroup --gid 1000 ${USER} \
    && adduser --disabled-password --gecos '' --uid 1000 --gid 1000 ${USER}

COPY --from=golang /usr/local/go/ /usr/local/go/
COPY --chown=${USER}:${USER} --from=golang /go/ /go/
COPY --chown=${USER}:${USER} . /${PROJECT_NAME}
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Things to do as $USER
USER ${USER}

ENV PIP_NO_CACHE_DIR=1
ENV UV_NO_CACHE=1

ENV HOME="/home/${USER}"
ENV VIRTUAL_ENV=${HOME}/.venv
ENV PATH="${VIRTUAL_ENV}/bin:${HOME}/.local/bin:${HOME}/bin:/go/bin:/usr/local/go/bin:${PATH}"

ENV GOPATH=/go
ENV TF_PLUGIN_CACHE_DIR=${HOME}/.terraform.d/plugin-cache

RUN mkdir -p "$TF_PLUGIN_CACHE_DIR"

RUN git config --global --add safe.directory /workdir \
    && git config --global --add safe.directory /${PROJECT_NAME}

RUN --mount=type=secret,id=GITHUB_ACCESS_TOKEN,mode=0400,uid=1000,gid=1000 \
    GITHUB_ACCESS_TOKEN="$(cat /run/secrets/GITHUB_ACCESS_TOKEN)" \
    make -C /${PROJECT_NAME} install/build

RUN python --version \
    && python3 --version \
    && python3.12 --version \
    && python3.13 --version \
    && python3.14 --version

WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["entrypoint.sh"]
