ARG NODE_IMAGE=node:24.21.0-bookworm-slim@sha256:0e0ff40c39bc087845bfb27465a0df4ea419520094bc35842ff83dd8cbe6f9b6

FROM ${NODE_IMAGE} AS production-dependencies

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm ci \
      --omit=dev \
      --ignore-scripts \
    && npm cache clean --force


FROM ${NODE_IMAGE} AS runtime

ENV NODE_ENV=production \
    PORT=3000

WORKDIR /app

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
