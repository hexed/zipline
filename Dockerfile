FROM node:16-alpine3.11 AS builder
WORKDIR /build

ENV NEXT_TELEMETRY_DISABLED=1

COPY src ./src
COPY server ./server
COPY scripts ./scripts
COPY prisma ./prisma

COPY package.json yarn.lock next.config.js next-env.d.ts zip-env.d.ts tsconfig.json ./

RUN yarn install

# create a mock config.toml to spoof next build!
RUN echo -e "[core]\nsecret = '12345678'\ndatabase_url = 'postgres://postgres:postgres@postgres/postgres'\n[uploader]\nroute = '/u'\ndirectory = './uploads'\n[urls]\nroute = '/go'" > config.toml

RUN yarn build

FROM node:16-alpine3.11 AS runner
WORKDIR /zipline

COPY --from=builder /build/node_modules ./node_modules

COPY --from=builder /build/src ./src
COPY --from=builder /build/server ./server
COPY --from=builder /build/scripts ./scripts
COPY --from=builder /build/prisma ./prisma
COPY --from=builder /build/.next ./.next
COPY --from=builder /build/tsconfig.json ./tsconfig.json
COPY --from=builder /build/package.json ./package.json

CMD ["node", "server"]