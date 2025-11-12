## Multi-stage build for File Browser - Kubernetes-optimized
## Simplified runtime container for use with init containers and K8s ConfigMaps/Secrets

# Build stage
FROM --platform=$BUILDPLATFORM registry.access.redhat.com/ubi9/nodejs-20:latest AS frontend-builder

USER root

# Build-time arguments
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Install pnpm
RUN npm install -g pnpm@9.15.4

# Copy frontend source
WORKDIR /src/frontend
COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY frontend/ ./
RUN pnpm run build

# Backend builder stage
FROM --platform=$BUILDPLATFORM registry.access.redhat.com/ubi9/go-toolset:1.22 AS backend-builder

USER root

# Build-time arguments
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG VERSION
ARG VERSION_HASH

# Set environment for cross-compilation
ENV GOOS=${TARGETOS:-linux}
ENV GOARCH=${TARGETARCH}
ENV CGO_ENABLED=0
ENV GOTOOLCHAIN=auto

# Install build dependencies for cross-compilation
RUN dnf install -y gcc gcc-c++ && dnf clean all

WORKDIR /src

# Copy go module files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Copy built frontend from previous stage
COPY --from=frontend-builder /src/frontend/dist ./frontend/dist

# Build the backend with embedded frontend
RUN GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} \
    go build -ldflags "-X 'github.com/filebrowser/filebrowser/v2/version.Version=${VERSION:-dev}' \
                       -X 'github.com/filebrowser/filebrowser/v2/version.CommitSHA=${VERSION_HASH:-unknown}'" \
    -o filebrowser .

# Final runtime stage - minimal, for use with init containers
FROM registry.access.redhat.com/ubi9-minimal:latest

# Install runtime dependencies (curl-minimal is already in ubi9-minimal)
RUN microdnf install -y ca-certificates tzdata shadow-utils && \
    microdnf clean all

# Create non-root user and directories
RUN groupadd -g 1000 filebrowser && \
    useradd -u 1000 -g filebrowser -s /sbin/nologin -M filebrowser && \
    mkdir -p /srv /config /database && \
    chown -R filebrowser:filebrowser /srv /config /database

# Copy binary from builder
COPY --from=backend-builder --chown=filebrowser:filebrowser /src/filebrowser /usr/local/bin/filebrowser

# Healthcheck script
COPY --chown=filebrowser:filebrowser docker/ubi/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Switch to non-root user
USER filebrowser

# Define volumes
VOLUME ["/srv", "/config", "/database"]

# Expose default port
EXPOSE 8080

# Healthcheck
HEALTHCHECK --start-period=5s --interval=10s --timeout=3s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

# Direct entrypoint - all configuration via environment variables
ENTRYPOINT ["/usr/local/bin/filebrowser"]

# No default args - filebrowser reads from FB_* environment variables
CMD []
