# syntax=docker/dockerfile:1

FROM quay.io/hummingbird/nodejs:24-builder AS deps
USER 0
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY package.json package-lock.json ./
RUN npm ci

FROM quay.io/hummingbird/nodejs:24-builder AS builder
USER 0
WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG NEXT_PUBLIC_API_BASE_URL
ENV NEXT_PUBLIC_API_BASE_URL=${NEXT_PUBLIC_API_BASE_URL}

RUN npm run build
RUN mkdir -p /runtime-cache /scratch

FROM quay.io/hummingbird/nodejs:24
USER 0
WORKDIR /srv/app

ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0 \
    PORT=3000 \
    HOME=/scratch \
    TMPDIR=/scratch

COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Keep the application immutable. Only runtime cache/temp paths are owned by the
# unprivileged process.
COPY --from=builder --chown=65532:65532 /runtime-cache ./.next/cache
COPY --from=builder --chown=65532:65532 /scratch /scratch

RUN ["/usr/bin/rm", "-rf", "/bin/sh", "/usr/bin/sh", "/bin/bash", "/usr/bin/bash", "/usr/bin/npm", "/usr/bin/npx", "/usr/lib/node_modules_24/npm", "/usr/local/bin/docker-entrypoint.sh", "/usr/bin/rm"]

USER 65532:65532
EXPOSE 3000
ENTRYPOINT ["node"]
CMD ["server.js"]
