# ---- Build stage ----
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o webhook-server .

# ---- Runtime stage ----
FROM alpine:3.19
RUN apk add --no-cache tzdata ca-certificates
WORKDIR /app
COPY --from=builder /app/webhook-server .
EXPOSE 10006
CMD ["./webhook-server"]
