FROM alpine:3.20

ARG LYCHEE_VERSION=0.15.1
ARG VALE_VERSION=2.29.6
ARG MARKDOWNLINT_VERSION=0.13.0
ARG CSPELL_VERSION=8.14.2

LABEL org.opencontainers.image.title="rulehub-doc-tools" \
    org.opencontainers.image.description="Pinned documentation tooling: lychee, markdownlint-cli2, vale" \
    org.opencontainers.image.source="https://github.com/rulehub/rulehub" \
    org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache nodejs npm curl tar gzip ca-certificates bash git && \
    npm install -g markdownlint-cli2@${MARKDOWNLINT_VERSION} markdownlint-cli2-config-standard@0.0.7 cspell@${CSPELL_VERSION} && \
    curl -sSL "https://github.com/lycheeverse/lychee/releases/download/v${LYCHEE_VERSION}/lychee-v${LYCHEE_VERSION}-x86_64-unknown-linux-gnu.tar.gz" -o /tmp/lychee.tar.gz && \
    tar -xzf /tmp/lychee.tar.gz -C /tmp && mv /tmp/lychee /usr/local/bin/lychee && \
    curl -sSL "https://github.com/errata-ai/vale/releases/download/v${VALE_VERSION}/vale_${VALE_VERSION}_Linux_64-bit.tar.gz" -o /tmp/vale.tar.gz && \
    tar -xzf /tmp/vale.tar.gz -C /tmp && mv /tmp/vale /usr/local/bin/vale && \
    chmod +x /usr/local/bin/lychee /usr/local/bin/vale && \
    rm -rf /var/cache/apk/* /tmp/*

RUN lychee --version && vale --version && markdownlint-cli2 --version || true

WORKDIR /workspace

ENTRYPOINT ["/bin/sh"]