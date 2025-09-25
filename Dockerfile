# Multi-stage Dockerfile for Inputly (Node.js ESM)

# 1) Base deps layer
FROM node:20-alpine AS base
WORKDIR /app
ENV NODE_ENV=production
COPY package*.json ./

# Install only production deps by default (can be overridden in dev stage)
RUN npm ci --only=production

# 2) Development layer (installs all deps and uses watch script)
FROM node:20-alpine AS dev
WORKDIR /app
ENV NODE_ENV=development
COPY package*.json ./
RUN npm install
COPY . .
# Expose typical dev port
EXPOSE 3000
CMD ["npm", "run", "dev"]

# 3) Production build layer
FROM base AS prod
# Re-copy full app and install prod deps
COPY . .
# Ensure any build step would run here if needed (none required for pure Node ESM)
# EXPOSE runtime port
EXPOSE 3000
# Start server
CMD ["node", "src/index.js"]
