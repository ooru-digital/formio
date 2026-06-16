# Used by docker-compose.yml to deploy the formio application
# (When modified, you must include `--build` )
# -----------------------------------------------------------
# Stage 1: Builder
FROM node:20-alpine as builder

WORKDIR /app

# Copy package files
COPY package.json /app/

# "bcrypt" requires python/make/g++, all must be installed in alpine
RUN apk update && \
    apk add make && \
    apk add python3 && \
    apk add g++ && \
    apk add git

# Use https to avoid requiring ssh keys for public repos.
RUN git config --global url."https://github.com/".insteadOf "ssh://git@github.com/"

# Install dependencies
RUN yarn install

RUN apk del git

# Copy source dependencies
COPY src/ /app/src/
COPY config/ /app/config
COPY *.js /app/
COPY *.txt /app/

# Stage 2: Runtime
FROM node:20-alpine

WORKDIR /app

# Copy from builder
COPY --from=builder /app/node_modules /app/node_modules
COPY --from=builder /app/src /app/src
COPY --from=builder /app/config /app/config
COPY --from=builder /app/*.js /app/
COPY --from=builder /app/*.txt /app/
COPY --from=builder /app/package.json /app/

# Set this to inspect more from the application. Examples:
#   DEBUG=formio:db (see index.js for more)
#   DEBUG=formio:*
ENV DEBUG=""

# This will initialize the application based on
# some questions to the user (login email, password, etc.)
ENTRYPOINT [ "node", "--no-node-snapshot", "main" ]
