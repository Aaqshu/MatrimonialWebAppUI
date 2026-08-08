# ---- build stage ----
FROM node:22-alpine AS builder
WORKDIR /app

# API app (standalone npm project)
COPY apps/api/package.json apps/api/package-lock.json ./apps/api/
WORKDIR /app/apps/api
RUN npm ci

# Full source + packages (provisioning reads migration SQLs at runtime)
COPY apps/api ./ 
COPY packages/database /app/packages/database
RUN npm run build

# ---- runtime stage ----
FROM node:22-alpine
WORKDIR /app

ENV NODE_ENV=production

COPY --from=builder /app/apps/api/package.json /app/apps/api/package-lock.json ./apps/api/
WORKDIR /app/apps/api
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=builder /app/apps/api/dist ./dist
COPY --from=builder /app/packages/database /app/packages/database

# uploads dir must be writable by node user (static assets)
RUN mkdir -p /app/apps/api/uploads && chown -R node:node /app/apps/api

USER node
EXPOSE 3001
CMD ["node", "dist/main.js"]
