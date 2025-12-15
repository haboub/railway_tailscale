FROM tailscale/tailscale:stable

ENV TS_SOCKET=/tmp/tailscaled.sock \
    TS_STATE_DIR=/var/lib/tailscale \
    TS_HOSTNAME=railway-ts \
    PORT=8080

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8080

CMD ["/usr/local/bin/start.sh"]