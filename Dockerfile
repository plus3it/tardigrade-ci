FROM golang:1.16.3-buster as golang
FROM quay.io/terraform-docs/terraform-docs:0.11.2 as tfdocs
FROM hashicorp/terraform:0.14.9 as terraform

FROM python:3.9.4-buster
ARG PROJECT_NAME=tardigrade-ci
ARG GITHUB_ACCESS_TOKEN
ENV PATH="/root/.local/bin:/root/bin:/go/bin:/usr/local/go/bin:${PATH}"
ENV GOPATH=/go
COPY --from=golang /go/ /go/
COPY --from=golang /usr/local/go/ /usr/local/go/
COPY --from=tfdocs /usr/local/bin/terraform-docs /usr/local/bin/
COPY --from=terraform /bin/terraform /usr/local/bin
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
