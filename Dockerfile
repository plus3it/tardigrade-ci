FROM golang:1.16.6-buster as golang

FROM python:3.9.6-buster

ARG PROJECT_NAME=tardigrade-ci
ARG GITHUB_ACCESS_TOKEN

ARG USER=${PROJECT_NAME}
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

# Things to do as root
USER root
RUN addgroup --gid ${USER_GID} ${USER} \
    && adduser --disabled-password --gecos '' --uid ${USER_UID} --gid ${USER_GID} ${USER}

COPY --from=golang /usr/local/go/ /usr/local/go/

RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
    jq \
    unzip \
    make \
    && touch /.dockerenv \
    && rm -rf /var/lib/apt/lists/*

# Things to do as $USER
USER ${USER}

ENV PATH="/${USER}/.local/bin:/${USER}/bin:/go/bin:/usr/local/go/bin:${PATH}"
ENV GOPATH=/go

COPY --chown=${USER}:${USER} --from=golang /go/ /go/
COPY --chown=${USER}:${USER} . /${PROJECT_NAME}
RUN make -C /${PROJECT_NAME} install

WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["make"]
