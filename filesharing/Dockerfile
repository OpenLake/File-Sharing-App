# Frontend Dockerfile for Flutter web application
FROM ghcr.io/cirruslabs/flutter:3.35.5 AS builder

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Enable web platform and get dependencies
RUN flutter config --enable-web \
    && flutter pub get

# Copy source code
COPY . .

# Build for web with environment variables
ARG API_BASE_URL=http://backend:8000
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL}

# Production stage - serve with nginx
FROM nginx:1.25-alpine

# Copy built web app to nginx html directory
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Expose port 80
EXPOSE 80

# Health check - use 127.0.0.1 instead of localhost for IPv4
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:80/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]