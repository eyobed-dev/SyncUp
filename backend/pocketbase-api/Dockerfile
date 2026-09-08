FROM node:20-alpine AS runtime

WORKDIR /app

COPY backend/pocketbase-api/package.json backend/pocketbase-api/package-lock.json* ./
RUN npm install --omit=dev

COPY backend/pocketbase-api/src ./src
COPY backend/pocketbase-api/scripts ./scripts
COPY assets/data/backend_seed.json /assets/data/backend_seed.json

EXPOSE 8080

CMD ["npm", "start"]

