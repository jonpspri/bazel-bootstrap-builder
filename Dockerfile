FROM ubuntu:bionic

SHELL ["/bin/bash", "-ueo", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
    build-essential openjdk-8-jdk-headless python python3 zip unzip wget \
 && rm -rf /var/lib/apt/lists/*

ARG BAZEL_VERSION=2.0.0
RUN mkdir -p "/bazel-${BAZEL_VERSION}"
WORKDIR /bazel-${BAZEL_VERSION}
COPY sha256sums /bazel-${BAZEL_VERSION}/sha256sums

ENV GITHUB_DOWNLOAD=https://github.com/bazelbuild/bazel/releases/download
RUN echo "Fetching Bazel ${BAZEL_VERSION}" \
 && wget -q "${GITHUB_DOWNLOAD}/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip" \
 && sha256sum -c <<< "$(grep "${BAZEL_VERSION}" ./sha256sums)" \
 && unzip "./bazel-${BAZEL_VERSION}-dist.zip" \
 && rm "./bazel-${BAZEL_VERSION}-dist.zip"

RUN echo "Building Bazel ${BAZEL_VERSION}" \
 && env EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk" bash ./compile.sh \
 && echo "Bazel is at /bazel-${BAZEL_VERSION}/output/bazel"
#  Bazel binary will be at /bazel-${BAZEL_VERSION}/output/bazel

WORKDIR /
RUN "/bazel-${BAZEL_VERSION}/output/bazel"
