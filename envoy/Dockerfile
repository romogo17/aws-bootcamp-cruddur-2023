FROM envoyproxy/envoy-dev:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -q install -y \
    curl
CMD ["/usr/local/bin/envoy", "-c", "/etc/envoy/envoy.yaml", "--service-cluster", "envoy", "-l", "debug"]