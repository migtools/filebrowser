# AGENTS.md — AI Agent Instructions for migtools/filebrowser

## Project Overview
This is the OADP fork of [File Browser](https://filebrowser.org), a web-based file management interface. It provides a file manager within a specified directory that can be used to upload, delete, preview, rename, and edit files. In the OADP ecosystem, this is used for browsing and restoring files from backup volumes. The fork is maintained on the `oadp-dev` branch.

- **Primary Language**: Go (backend) + Vue.js (frontend)
- **Module**: `github.com/filebrowser/filebrowser/v2`
- **Default Branch**: `oadp-dev`

## Build Instructions
```bash
# Build the Go binary
go build -o filebrowser .

# Build with the frontend embedded (requires Node.js)
# Frontend is pre-built in www/ or built from frontend/
cd frontend && npm install && npm run build && cd ..
go build -o filebrowser .
```

## Test Instructions
```bash
# Run all Go tests
go test ./...

# Run tests for a specific package
go test ./http/... -run TestName

# Vet code
go vet ./...
```

## Linting
```bash
# Run golangci-lint (configuration in .golangci.yml)
golangci-lint run ./...
```

Configuration: `.golangci.yml`

## Code Conventions
- Backend is Go with standard library HTTP handlers
- Frontend is Vue.js in `frontend/` directory
- Pre-built frontend assets in `www/`
- Storage abstraction layer in `storage/`
- Authentication system in `auth/`
- Error types in `errors/`
- File operations in `files/` and `fileutils/`

## Project Structure
```
auth/          - Authentication providers (JSON, proxy, hook, none)
cmd/           - CLI command definitions
diskcache/     - Disk-based caching
errors/        - Custom error types
files/         - File listing and info models
fileutils/     - File utility operations
frontend/      - Vue.js frontend source
http/           - HTTP handlers and routing
img/           - Image processing (thumbnails)
rules/         - File access rules
runner/        - Command runner for hooks
search/        - File search functionality
settings/      - Application settings
share/         - File sharing
storage/       - Storage backends (bolt, JSON)
users/         - User management
version/       - Version info
www/           - Pre-built frontend assets
docker/        - Docker build files
```

## CI/CD
- GitHub Actions workflows in `.github/workflows/`:
  - `docs.yml` — Documentation builds
- Linter config: `.golangci.yml`
- Reproduce CI locally:
  ```bash
  go vet ./...
  golangci-lint run ./...
  go test ./...
  ```

## Common Tasks

### Adding a new authentication provider
1. Create provider in `auth/`
2. Implement the `Auther` interface
3. Register in `cmd/` CLI flags

### Adding a new storage backend
1. Implement the `storage.Store` interface in `storage/`
2. Register in the application initialization

### Modifying HTTP API endpoints
1. Handlers are in `http/`
2. Follow existing handler patterns with middleware chains
