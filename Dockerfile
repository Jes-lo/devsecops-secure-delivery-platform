ARG NODE_IMAGE=node:24.21.0-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20
ARG PERL_BASE_VERSION=5.36.0-7+deb12u4

FROM ${NODE_IMAGE} AS patched-base
ARG PERL_BASE_VERSION

RUN apt-get update \
    && apt-get install --yes --no-install-recommends --only-upgrade \
      "perl-base=${PERL_BASE_VERSION}" \
    && rm -rf /var/lib/apt/lists/*

FROM patched-base AS production-dependencies

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci \
      --omit=dev \
      --ignore-scripts \
    && npm cache clean --force


FROM patched-base AS runtime

ENV NODE_ENV=production \
    PORT=3000

WORKDIR /app

RUN rm -rf \
      /usr/local/lib/node_modules/npm \
      /usr/local/lib/node_modules/corepack \
      /opt/yarn-v1.22.22 \
    && rm -f \
      /usr/local/bin/npm \
      /usr/local/bin/npx \
      /usr/local/bin/corepack \
      /usr/local/bin/yarn \
      /usr/local/bin/yarnpkg

COPY --from=production-dependencies \
  --chown=node:node \
  /app/node_modules \
  ./node_modules

COPY --chown=node:node package.json ./package.json
COPY --chown=node:node src ./src

USER node

EXPOSE 3000

STOPSIGNAL SIGTERM

HEALTHCHECK \
  --interval=30s \
  --timeout=3s \
  --start-period=5s \
  --retries=3 \
  CMD ["node", "-e", "fetch('http://127.0.0.1:3000/health').then(r => { if (!r.ok) process.exit(1); }).catch(() => process.exit(1));"]

CMD ["node", "src/server.js"]
