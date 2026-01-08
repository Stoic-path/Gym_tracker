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
RUN pnpm build

# --- Stage 2: Production Server (Nginx) ---
FROM nginx:alpine

# Copy built files from the previous stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Basic configuration for SPA (Single Page Application)
# This prevents 404 errors when reloading internal pages
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]