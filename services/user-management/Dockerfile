# base
FROM node:18.6.0 AS base

WORKDIR /usr/src/app

COPY package*.json ./
    
RUN npm install

COPY . .

RUN npm run build

# for production

FROM node:18.6.0-alpine3.15

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install --only=production

COPY --from=base /usr/src/app/dist ./

EXPOSE 5101

ENTRYPOINT ["node","./index.js"]