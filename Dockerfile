### This is the build stage, with dev dependencies
FROM node:16-alpine AS builder

# Omits Yarn interactive logs if set to 'true'
ARG CI

WORKDIR /build

COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn ./.yarn
RUN yarn install --immutable

COPY . .

RUN yarn build



### This is the production stage, without dev dependencies
FROM node:16-alpine as production

# Omits Yarn interactive logs if set to 'true'
ARG CI
# Used by Sentry to tag releases when logging errors
ARG COMMIT_HASH

WORKDIR /usr/src/app

ENV PORT 3001
ENV HOST 0.0.0.0
EXPOSE 3001

COPY package.json yarn.lock .yarnrc.yml  ./
COPY .yarn ./.yarn
# Install only production dependencies
RUN yarn workspaces focus --production

COPY --from=builder /build/dist .
COPY .env* .

ENV COMMIT_HASH $COMMIT_HASH

RUN addgroup -g 1001 -S nodejs
RUN adduser -S track -u 1001
USER track

CMD ["node", "main"]
