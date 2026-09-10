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

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/drizzle ./drizzle
COPY --from=build /app/package.json ./package.json

RUN mkdir -p /data

EXPOSE 4700

ENTRYPOINT ["node", "dist/cli.js"]
CMD ["serve", "--host", "0.0.0.0", "--port", "4700"]
