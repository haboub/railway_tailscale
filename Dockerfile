FROM tailscale/tailscale:stable

ENV TS_SOCKET=/tmp/tailscaled.sock \
    TS_STATE_DIR=/var/lib/tailscale \
    TS_HOSTNAME=railway-ts \
    PORT=8080

# tailscale image is Alpine-based; install Python for the tiny health server
RUN apk add --no-cache python3

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8080

CMD ["/usr/local/bin/start.sh"]