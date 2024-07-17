###################
# BUILD FOR LOCAL DEVELOPMENT
###################

FROM node:14-alpine As build

WORKDIR /usr/src/app

RUN apk add --no-cache --virtual .gyp python3 py3-pip make g++

# Copy and build NestJS server project
COPY --chown=node:node package*.json ./
COPY --chown=node:node tsconfig.build.json ./
COPY --chown=node:node tsconfig.json ./
COPY --chown=node:node nest-cli.json ./
COPY --chown=node:node mikro-orm.config.ts ./
COPY --chown=node:node .env ./
COPY --chown=node:node config ./config
COPY --chown=node:node keycloak ./keycloak
COPY --chown=node:node src ./src

RUN npm ci
RUN npm run build
RUN npm prune --production

# Copy and build client project
COPY --chown=node:node client/package*.json ./client/
COPY --chown=node:node client/src ./client/src
COPY --chown=node:node client/public ./client/public
COPY --chown=node:node client/typings ./client/typings
COPY --chown=node:node client/vcs ./client/vcs
COPY --chown=node:node client/tsconfig.json ./client/tsconfig.json

ENV CYPRESS_INSTALL_BINARY=0
RUN npm ci --prefix=client
RUN npm run build --prefix=client

RUN apk del .gyp

USER node

###################
# PRODUCTION
###################

FROM node:14-alpine As production

WORKDIR /usr/src/app

COPY --chown=node:node nest-cli.json ./
COPY --chown=node:node mikro-orm.config.ts ./
COPY --chown=node:node .env ./
COPY --chown=node:node config ./config
COPY --chown=node:node keycloak ./keycloak

COPY --chown=node:node --from=build /usr/src/app/node_modules ./node_modules
COPY --chown=node:node --from=build /usr/src/app/package*.json ./
COPY --chown=node:node --from=build /usr/src/app/dist ./dist

COPY --chown=node:node --from=build /usr/src/app/client/build ./client/build
COPY --chown=node:node --from=build /usr/src/app/client/vcs ./client/vcs

CMD ["npm", "run", "start:prod"]
