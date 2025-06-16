# Stage 1: Builder
# Uses the official Node.js 20 LTS image as the base image for building the Next.js application.
FROM node:20-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock) to leverage Docker cache for dependencies.
# This step allows npm ci to run and cache dependencies before copying the rest of the app.
COPY package.json package-lock.json ./

# Install Node.js dependencies
# `npm ci` performs a clean and deterministic installation based on package-lock.json.
RUN npm ci

# Copy the rest of the application code
COPY . .

# Build the Next.js application for production.
# This command generates the optimized production build in the ./.next directory.
RUN npm run build

# Stage 2: Production Runtime
# Uses a lean Node.js 20 Alpine image for the final production environment.
# This keeps the final Docker image size minimal for faster deployments and lower resource usage.
FROM node:20-alpine

# Set the working directory inside the container for the production stage.
WORKDIR /app

# Copy only the necessary files from the builder stage to the production stage.
# .next: Contains the optimized Next.js build output.
COPY --from=builder /app/.next ./.next
# public: Contains static assets served by Next.js.
COPY --from=builder /app/public ./public
# node_modules: Contains the installed Node.js dependencies required at runtime.
COPY --from=builder /app/node_modules ./node_modules
# package.json: Needed by `next start` for scripts and metadata.
COPY --from=builder /app/package.json ./package.json
# src: CRITICAL: Copy the source directory as Next.js API routes/server components may need it at runtime.
# This is often the fix for "module not found" errors related to Next.js's internal modules like jsx-runtime.
COPY --from=builder /app/src ./src

# Set environment variables for production mode and the port.
# NODE_ENV=production tells Next.js to run in production mode.
ENV NODE_ENV=production
# PORT is expected by Cloud Run. 8080 is a common choice and matches EXPOSE.
ENV PORT=8080

# Expose the port on which the Next.js application will listen.
EXPOSE 8080

# Define the command to start the Next.js production server.
# `npx next start` runs the Next.js server.
# `-p $PORT` tells Next.js to listen on the port specified by the PORT environment variable.
# This makes the application compliant with Cloud Run's expectation.
CMD ["npx", "next", "start", "-p", "8080"]
