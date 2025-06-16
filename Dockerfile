# Install & build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production runtime
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080
CMD ["npx", "next", "start", "-p", "8080"]
