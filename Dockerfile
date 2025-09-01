# ---------------------------
# Base
# ---------------------------
FROM golang:1.24.6-alpine3.22 AS base

# Set env CGO to enabled
# CGO_ENABLED=1 is required for libraries like sqlite3 that use C bindings.
ENV CGO_ENABLED=1

# Install C build tools for CGO
# gcc and musl-dev are required on Alpine sqlite tool for db manipulation
RUN apk add --no-cache gcc musl-dev sqlite npm nodejs

# Install go tools
RUN go install github.com/a-h/templ/cmd/templ@latest
RUN go install github.com/pressly/goose/v3/cmd/goose@latest
RUN go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

# ---------------------------
# Development
# ---------------------------
FROM base AS development

# Setup working directory
WORKDIR /app

# Copy go dependencies file
COPY go.mod go.sum ./

# Install go dependencies
RUN go mod download

# Install modd to hot reload app
RUN go install github.com/cortesi/modd/cmd/modd@latest

# Create /data dir for database
RUN mkdir -p /data

# Start modd
CMD ["modd"]

# ---------------------------
# Build
# ---------------------------
FROM base AS build

# Setup working directory
WORKDIR /build

# Copy go dependencies file
COPY go.mod go.sum ./

# Install go dependencies
RUN go mod download

# Copy npm dependencies file
COPY package.json package-lock.json ./

# Install npm dependencies
RUN npm install

# Copy source
COPY . .

# Build go templates
RUN templ generate

# Build css styles
RUN npm run build

# Generate go stores
RUN sqlc generate

# Build Go app
# -o /app/main specifies the output file name and location.
# -ldflags="-w -s" strips debugging information, reducing the binary size.
RUN GOOS=linux go build -a -ldflags="-w -s" -o /build/entrypoint .

# ---------------------------
# Production
# ---------------------------
# Use Alpine for small image size
FROM alpine:3.22 AS production

# Install ca-certificates and sqlite3 for runtime
RUN apk --no-cache add ca-certificates sqlite

# Create non-root user
RUN adduser -D nonroot

# Create data dir with nonroot owner
RUN mkdir -p /data && chown -R nonroot:nonroot /data

# Set working directory
WORKDIR /prod

# Copy binaries from the 'build' stage
COPY --from=build --chown=nonroot:nonroot \
  /build/entrypoint \
  /go/bin/goose \
  ./

# Copy migration files
COPY --from=build --chown=nonroot:nonroot \
  /build/migrations \
  ./migrations

# Switch to nonroot user
USER nonroot

# Start app
CMD ["./entrypoint"]
