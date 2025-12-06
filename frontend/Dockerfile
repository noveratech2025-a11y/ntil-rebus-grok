# NTIL REBUS-GROK Frontend
# Multi-stage build for minimal production image

# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source
COPY public ./public
COPY src ./src
COPY tsconfig.json ./

# Build
RUN npm run build

# Runtime stage
FROM node:20-alpine

# Install serve to run the application
RUN npm install -g serve

# Security: Run as non-root
RUN addgroup -g 1000 rebus && \
    adduser -u 1000 -G rebus -s /bin/sh -D rebus

WORKDIR /app

# Copy built application
COPY --from=builder /app/build ./build

# Set ownership
RUN chown -R rebus:rebus /app
USER rebus

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3000', (res) => {if (res.statusCode !== 200) throw new Error(res.statusCode)})" || exit 1

EXPOSE 3000
CMD ["serve", "-s", "build", "-l", "3000"]
