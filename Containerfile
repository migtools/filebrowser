## Multi-stage build for File Browser

# =============================================================================
# Stage 1: Install frontend dependencies only when needed
# =============================================================================
FROM registry.access.redhat.com/ubi9/nodejs-24:latest AS frontend-deps

USER 0
WORKDIR /app

# Install pnpm globally
RUN npm install -g pnpm@10.29.2

# Copy only dependency files for better layer caching
COPY frontend/package.json frontend/pnpm-lock.yaml ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# =============================================================================
# Stage 2: Build frontend
# =============================================================================
FROM registry.access.redhat.com/ubi9/nodejs-24:latest AS frontend-builder

USER 0
WORKDIR /app

# Install pnpm (needed for build scripts)
RUN npm install -g pnpm@10.29.2

# Copy node_modules from deps stage
COPY --from=frontend-deps /app/node_modules ./node_modules

# Copy frontend source
COPY frontend/ ./

# Build the frontend
RUN pnpm run build

# =============================================================================
# Stage 3: Build Go backend
# =============================================================================
FROM --platform=$BUILDPLATFORM quay.io/konveyor/builder:ubi9-latest AS backend-builder

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

WORKDIR /src

# Copy go module files first for better layer caching
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Copy built frontend from previous stage
COPY --from=frontend-builder /app/dist ./frontend/dist

# Build the backend with embedded frontend
RUN go build -ldflags "-s -w \
    -X 'github.com/filebrowser/filebrowser/v2/version.Version=${VERSION:-dev}' \
    -X 'github.com/filebrowser/filebrowser/v2/version.CommitSHA=${VERSION_HASH:-unknown}'" \
    -o filebrowser .

# =============================================================================
# Stage 4: Final runtime image - minimal footprint
# =============================================================================
FROM registry.access.redhat.com/ubi9-minimal:latest

# Labels for container metadata
LABEL name="filebrowser" \
      summary="File Browser - Web-based file manager" \
      description="A web-based file manager with support for multiple users and permissions" \
      io.k8s.display-name="File Browser" \
      io.k8s.description="A web-based file manager with support for multiple users and permissions" \
      io.openshift.tags="filebrowser,filemanager,web"

# Install runtime dependencies and clean up in single layer
RUN microdnf install -y --nodocs \
        ca-certificates \
        tzdata \
        shadow-utils \
        curl-minimal && \
    microdnf clean all && \
    rm -rf /var/cache/yum

# Create non-root user and required directories
RUN groupadd -g 1001 filebrowser && \
    useradd -u 1001 -g filebrowser -s /sbin/nologin -M filebrowser && \
    mkdir -p /srv /config /database && \
    chown -R 1001:1001 /srv /config /database

# Copy binary from builder
COPY --from=backend-builder --chown=1001:1001 /src/filebrowser /usr/local/bin/filebrowser

# Copy healthcheck script
COPY --chown=1001:1001 docker/ubi/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Switch to non-root user (using numeric ID for OpenShift compatibility)
USER 1001

# Define volumes for persistent data
VOLUME ["/srv", "/config", "/database"]

# Expose default port
EXPOSE 8080

# Healthcheck using the script
HEALTHCHECK --start-period=5s --interval=30s --timeout=3s --retries=3 \
    CMD ["/usr/local/bin/healthcheck.sh"]

# Direct entrypoint - configuration via FB_* environment variables
ENTRYPOINT ["/usr/local/bin/filebrowser"]
CMD []
