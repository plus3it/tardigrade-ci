# syntax=docker/dockerfile:1

FROM golang:1.26-bookworm AS golang

FROM debian:bookworm-slim@sha256:4724b8cc51e33e398f0e2e15e18d5ec2851ff0c2280647e1310bc1642182655d

ARG PROJECT_NAME=tardigrade-ci

ENV USER=${PROJECT_NAME}
ENV USER_UID=1001
ENV USER_GID=${USER_UID}

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

RUN addgroup --gid ${USER_GID} ${USER} \
    && adduser --disabled-password --gecos '' --uid ${USER_UID} --gid ${USER_GID} ${USER}

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

RUN --mount=type=secret,id=GITHUB_ACCESS_TOKEN,mode=0400,uid=${USER_UID},gid=${USER_GID} \
    GITHUB_ACCESS_TOKEN="$(cat /run/secrets/GITHUB_ACCESS_TOKEN)" \
    make -C /${PROJECT_NAME} install/build

RUN python --version \
    && python3 --version \
    && python3.12 --version \
    && python3.13 --version \
    && python3.14 --version

WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["entrypoint.sh"]
