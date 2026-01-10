# --- Stage 1: Build (Builder) ---
FROM node:22-alpine AS builder

# Enable pnpm via corepack (native in newer Node versions)
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copy dependency files first to leverage Docker cache
COPY package.json ./

# Install dependencies
RUN pnpm install

# Copy the rest of the code
COPY . .

# Build the application (generates /dist folder)
RUN pnpm run build

# --- Stage 2: Production Server (Nginx) ---
FROM nginx:alpine

# Copy built files from the previous stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf


EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]