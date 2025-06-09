# syntax=docker/dockerfile:1

FROM golang:1.24.4-bookworm AS golang

FROM python:3.13.3-bookworm

ARG PROJECT_NAME=tardigrade-ci

ENV USER=${PROJECT_NAME}
ENV USER_UID=1000
ENV USER_GID=${USER_UID}

# Things to do as root
USER root

RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
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

RUN addgroup --gid ${USER_GID} ${USER} \
    && adduser --disabled-password --gecos '' --uid ${USER_UID} --gid ${USER_GID} ${USER}

COPY --from=golang /usr/local/go/ /usr/local/go/
COPY --chown=${USER}:${USER} --from=golang /go/ /go/
COPY --chown=${USER}:${USER} . /${PROJECT_NAME}
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN --mount=type=secret,id=GITHUB_ACCESS_TOKEN,env=GITHUB_ACCESS_TOKEN \
    make -C /${PROJECT_NAME} fixuid/install \
    && cp /root/bin/fixuid /usr/local/bin/fixuid \
    && chown root:root /usr/local/bin/fixuid \
    && chmod 4755 /usr/local/bin/fixuid\
    && mkdir -p /etc/fixuid \
    && printf "user: $USER\ngroup: $USER\n" > /etc/fixuid/config.yml

# Things to do as $USER
USER ${USER}

ENV HOME="/home/${USER}"
ENV PYENV_ROOT=${HOME}/.pyenv
ENV PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:${HOME}/.local/bin:${HOME}/bin:/go/bin:/usr/local/go/bin:${PATH}"
ENV GOPATH=/go

RUN --mount=type=secret,id=GITHUB_ACCESS_TOKEN,env=GITHUB_ACCESS_TOKEN \
    make -C /${PROJECT_NAME} install

# Install python versions
RUN --mount=type=secret,id=GITHUB_ACCESS_TOKEN,env=GITHUB_ACCESS_TOKEN \
    make -C /${PROJECT_NAME} python312/install
RUN pyenv global system $(pyenv versions | grep 3.12)
RUN python --version \
    && python3 --version \
    && python3.12 --version

WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["entrypoint.sh"]
