# --- Etapa 1: Construcción (Builder) ---
FROM node:22-alpine AS builder

# Habilitar pnpm mediante corepack (nativo en Node nuevos)
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Copiamos primero los archivos de dependencia para aprovechar caché de Docker
COPY package.json ./

# Instalamos dependencias
RUN pnpm install

# Copiamos el resto del código
COPY . .

# Construimos la aplicación (genera la carpeta /dist)
RUN pnpm build

# --- Etapa 2: Servidor Producción (Nginx) ---
FROM nginx:alpine

# Copiamos los archivos construidos desde la etapa anterior
COPY --from=builder /app/dist /usr/share/nginx/html

# Configuración básica para SPA (Single Page Application)
# Esto evita errores 404 al recargar páginas internas
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