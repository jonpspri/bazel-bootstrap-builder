FROM ubuntu:bionic

SHELL ["/bin/bash", "-ueo", "pipefail", "-c"]

ARG JDK_PACKAGE=adoptopenjdk-11-hotspot
# hadolint ignore=DL3008
RUN :; \
 apt-get update && apt-get install --no-install-recommends -y \
       ca-certificates wget gnupg software-properties-common \
       build-essential python python3 zip unzip wget ; \
 if [ "${JDK_PACKAGE%%-*}" == adoptopenjdk ]; then \
    wget -qO - https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public \
        | apt-key add - ;\
    add-apt-repository --yes https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ ; \
    apt-get update ; \
 fi ; \
 apt-get install --no-install-recommends -y ${JDK_PACKAGE} ; \
 rm -rf /var/lib/apt/lists/* ;\
 :

ARG BAZEL_VERSION=2.0.0
RUN mkdir -p "/bazel-${BAZEL_VERSION}"
WORKDIR /bazel-${BAZEL_VERSION}
COPY sha256sums /bazel-${BAZEL_VERSION}/sha256sums

ENV GITHUB_DOWNLOAD=https://github.com/bazelbuild/bazel/releases/download
RUN echo "Fetching Bazel ${BAZEL_VERSION}" \
 && wget -q "${GITHUB_DOWNLOAD}/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-dist.zip" \
 && sha256sum -c <<< "$(grep "${BAZEL_VERSION}" ./sha256sums)" \
 && unzip -q "./bazel-${BAZEL_VERSION}-dist.zip" \
 && rm "./bazel-${BAZEL_VERSION}-dist.zip"

COPY bazel.diff /bazel-${BAZEL_VERSION}/bazel.diff
RUN patch -p1 < ./bazel.diff

ENV BAZEL_JAVAC_OPTS="-J-Xmx2g -J-Xms500m -J-Xmn750m -J-verbose:gc"
ENV EXTRA_BAZEL_ARGS="--host_javabase=@local_jdk//:jdk"
RUN echo "Building Bazel ${BAZEL_VERSION}" \
 && ./compile.sh \
 && echo "Bazel is at /bazel-${BAZEL_VERSION}/output/bazel"
#  Bazel binary will be at /bazel-${BAZEL_VERSION}/output/bazel

#WORKDIR /
#RUN "/bazel-${BAZEL_VERSION}/output/bazel"
