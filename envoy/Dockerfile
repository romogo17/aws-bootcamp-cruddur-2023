FROM envoyproxy/envoy-dev:latest

ARG CONFIG_FILE=envoy.yaml
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -q install -y curl dnsutils netcat

COPY $CONFIG_FILE /etc/envoy/envoy.yaml

# envoy
EXPOSE 8800
# admin
EXPOSE 8001

CMD ["/usr/local/bin/envoy", "-c", "/etc/envoy/envoy.yaml", "--service-cluster", "envoy", "-l", "debug", "--base-id", "1"]