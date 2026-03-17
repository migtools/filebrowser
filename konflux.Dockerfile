# =============================================================================
# Stage 1: Build frontend
# =============================================================================
FROM registry.access.redhat.com/ubi9/nodejs-24:latest AS frontend-builder

USER 0
WORKDIR /app

RUN npm install -g pnpm@10.29.2

COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY frontend/ ./
RUN pnpm run build

# =============================================================================
# Stage 2: Build Go backend
# =============================================================================
FROM brew.registry.redhat.io/rh-osbs/openshift-golang-builder:rhel_9_golang_1.25 AS builder

COPY . .
WORKDIR $APP_ROOT/app/
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download
COPY . .
COPY --from=frontend-builder /app/dist ./frontend/dist

ENV BUILDTAGS strictfipsruntime
ENV GOEXPERIMENT strictfipsruntime
RUN CGO_ENABLED=1 GOOS=linux go build -tags "$BUILDTAGS" -mod=mod -a -o filebrowser .

# =============================================================================
# Stage 3: Runtime image
# =============================================================================
FROM registry.redhat.io/ubi9/ubi:latest

COPY --from=builder $APP_ROOT/app/filebrowser /filebrowser

USER 65532:65532

EXPOSE 8080

ENTRYPOINT ["/filebrowser"]
CMD []

LABEL description="OADP VM file restore file browser"
LABEL io.k8s.description=" OADP VM file restore file browser"
LABEL io.k8s.display-name="OADP File Browser"
LABEL io.openshift.tags="filebrowser,filemanager,web"
LABEL summary="OADP File Browser"
