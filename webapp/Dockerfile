# Stage 1: Build React static bundle
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

# Stage 2: Production server wrapper
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

# Copy built app and server wrapper from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server.js ./server.js

EXPOSE 3000

CMD ["node", "server.js"]
