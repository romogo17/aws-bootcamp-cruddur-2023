FROM envoyproxy/envoy-dev:latest

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get -q install -y curl

COPY envoy.yaml /etc/envoy/envoy.yaml

# envoy
EXPOSE 8800
# admin
EXPOSE 8001

CMD ["/usr/local/bin/envoy", "-c", "/etc/envoy/envoy.yaml", "--service-cluster", "envoy", "-l", "debug"]