# syntax=docker/dockerfile:1

FROM golang:1.25.3-alpine AS builder
WORKDIR /app

# Dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy source
COPY . .

# Build binary
RUN go build -o pixsync ./cmd/server

# Final image
FROM alpine:latest
WORKDIR /app

# Copy binary
COPY --from=builder /app/pixsync /app/pixsync

EXPOSE 8080

CMD ["/app/pixsync"]