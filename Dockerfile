FROM golang:1.16.3-buster as golang

FROM quay.io/terraform-docs/terraform-docs:0.12.1 as tfdocs

FROM koalaman/shellcheck:v0.7.2 as shellcheck

FROM bats/bats:1.2.1 as bats

FROM mstruebing/editorconfig-checker:2.3.5 as ec

FROM hashicorp/terraform:0.15.0 as terraform

FROM mikefarah/yq:4.7.0 as yq

FROM python:3.9.4-buster

ARG PROJECT_NAME=tardigrade-ci
ARG GITHUB_ACCESS_TOKEN
ENV PATH="/root/.local/bin:/root/bin:/go/bin:/usr/local/go/bin:${PATH}"
ENV GOPATH=/go
COPY --from=golang /go/ /go/
COPY --from=golang /usr/local/go/ /usr/local/go/
COPY --from=tfdocs /usr/local/bin/terraform-docs /usr/local/bin/
COPY --from=terraform /bin/terraform /usr/local/bin/
COPY --from=shellcheck /bin/shellcheck /usr/local/bin/
COPY --from=bats /opt/bats /opt/bats
COPY --from=ec /usr/bin/ec /usr/local/bin/ec
COPY --from=yq /usr/bin/yq /usr/local/bin/yq
COPY . /${PROJECT_NAME}
RUN apt-get update -y && apt-get install -y \
    xz-utils \
    curl \
    jq \
    unzip \
    make \
    && ln -s /opt/bats/bin/bats /usr/local/bin/bats \
    && python -m pip install --no-cache-dir -r /${PROJECT_NAME}/requirements.txt \
    && touch /.dockerenv \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["make"]
