#
# ----- Go Builder Image ------
#
FROM alexellis2/go-armhf:1.8.4

RUN apk add --no-cache git

# set working directory
RUN mkdir -p /go/src/drone-helm
WORKDIR /go/src/drone-helm

# copy sources
COPY . .

# add dependencies
RUN go get

# run tests
RUN go test -v

# build binary
RUN go build -v -o "/drone-helm"

#
# ------ Drone-Helm plugin image ------
#

FROM armhf/alpine:3.5
MAINTAINER Ivan Pedrazas <ipedrazas@gmail.com>

# Helm version: can be passed at build time (default to v2.6.0)
ARG VERSION
ENV VERSION ${VERSION:-v2.7.0}
ENV FILENAME helm-${VERSION}-linux-arm.tar.gz

ARG KUBECTL
ENV KUBECTL ${KUBECTL:-v1.8.1}

RUN set -ex \
  && apk add --no-cache curl ca-certificates \
  && curl -o /tmp/${FILENAME} http://storage.googleapis.com/kubernetes-helm/${FILENAME} \
  && curl -o /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL}/bin/linux/arm/kubectl \
  && tar -zxvf /tmp/${FILENAME} -C /tmp \
  && mv /tmp/linux-arm/helm /bin/helm \
  && chmod +x /tmp/kubectl \
  && mv /tmp/kubectl /bin/kubectl \
  && rm -rf /tmp/*

LABEL description="Kubectl and Helm."
LABEL base="alpine"

COPY --from=0 /drone-helm /bin/drone-helm
COPY kubeconfig /root/.kube/kubeconfig

ENTRYPOINT [ "/bin/drone-helm" ]
