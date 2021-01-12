FROM golang:1.15.6-buster as golang
FROM python:3.9.1-buster
ARG PROJECT_NAME=tardigrade-ci
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
COPY . /${PROJECT_NAME}
RUN make -C /${PROJECT_NAME} install
WORKDIR /${PROJECT_NAME}
ENTRYPOINT ["make"]
