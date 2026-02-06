# Dockerfile Actual Budget 26.2.0 para QNAP TS-431P3 ARMv7 32k
# Compilación cruzada desde Linux Mint x86_64
# Fecha: Febrero 2026

# STAGE 1: Builder - Recompilación de better-sqlite3 con soporte 32k
FROM --platform=linux/arm/v7 node:18-bullseye-slim AS builder

# Instalar herramientas para recompilar
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copiar la app desde la imagen oficial (SIN la "v" en el tag)
COPY --from=actualbudget/actual-server:26.2.0 /app /app
WORKDIR /app

# El truco CRÍTICO para QNAP Alpine AL314 - páginas de 32k
ENV LDFLAGS="-Wl,-z,max-page-size=32768"

# Recompilar better-sqlite3 DENTRO de Debian con el flag de 32k
RUN npm rebuild better-sqlite3 --build-from-source

# STAGE 2: Imagen final - Debian para máxima compatibilidad
FROM --platform=linux/arm/v7 node:18-bullseye-slim

# Instalar dependencias runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl ca-certificates dumb-init \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de datos
RUN mkdir -p /data

# Copiar la app con better-sqlite3 recompilado
COPY --from=builder /app /app
WORKDIR /app

# Variables de entorno
ENV NODE_ENV=production
ENV ACTUAL_DATA_DIR=/data
ENV ACTUAL_PORT=5006
ENV ACTUAL_HOSTNAME=0.0.0.0

# Exponer puerto
EXPOSE 5006

# Usar dumb-init para manejar señales correctamente
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "app.js"]
