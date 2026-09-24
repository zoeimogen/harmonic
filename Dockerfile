FROM node:22-slim AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts

COPY . .
RUN npm run build \
    && npm prune --omit=dev --ignore-scripts

FROM node:22-slim AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    HARMONIC_DATA_DIR=/data

RUN DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y git curl python3

RUN curl -fsSL https://get.docker.com -o install-docker.sh && \
    sh install-docker.sh && \
    rm install-docker.sh

RUN DEBIAN_FRONTEND=noninteractive apt install -y python3.11-venv
RUN curl -fsSL -o get-platformio.py https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py && \
    python3 get-platformio.py && \
    rm get-platformio.py

RUN DEBIAN_FRONTEND=noninteractive apt install -y python3-pip
RUN pip3 install --break-system-packages esptool platformio

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/drizzle ./drizzle
COPY --from=build /app/package.json ./package.json

RUN mkdir -p /data

EXPOSE 4700

ENTRYPOINT ["node", "dist/cli.js"]
CMD ["serve", "--host", "0.0.0.0", "--port", "4700"]
