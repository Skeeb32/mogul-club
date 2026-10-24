FROM node:22.23.4-bookworm-slim AS base
ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN npm install -g pnpm@10.33.0
WORKDIR /app
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm --filter @mogul/contracts build && pnpm --filter @mogul/api build
FROM base AS api
USER node
CMD ["node", "apps/api/dist/src/main.js"]
FROM base AS admin-build
RUN pnpm --filter @mogul/admin build
FROM node:22.23.4-bookworm-slim AS admin
WORKDIR /app
ENV NODE_ENV=production
COPY --from=admin-build --chown=node:node /app/apps/admin/.next/standalone ./
COPY --from=admin-build --chown=node:node /app/apps/admin/.next/static ./apps/admin/.next/static
USER node
ENV HOSTNAME=0.0.0.0
ENV PORT=3000
CMD ["node", "apps/admin/server.js"]
