# Simple App – REST API + DevOps Automation

A minimal but production‑ready Flask REST API that demonstrates modern DevOps practices: containerisation (Docker), orchestration (Docker Compose), automated testing & CI (GitHub Actions), server diagnostics (Bash), and infrastructure automation (Ansible). Built for Python 3.12+.

## Table of Contents

- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
  - [Local Development](#local-development)
  - [Using Docker Compose](#using-docker-compose)
- [API Reference](#api-reference)
  - [Endpoints](#endpoints)
  - [Example `curl` Commands](#example-curl-commands)
- [Testing](#testing)
- [Diagnostics Script (Bash)](#diagnostics-script-bash)
- [Docker & Docker Compose Details](#docker--docker-compose-details)
- [Ansible Automation](#ansible-automation)
  - [Inventory & Variables](#inventory--variables)
  - [Running the Playbook](#running-the-playbook)
- [GitHub Actions CI/CD](#github-actions-cicd)
- [Makefile Commands](#makefile-commands)
- [Contributing & License](#contributing--license)

## Features

- **REST API** – CRUD operations on an in‑memory user store with proper HTTP status codes and JSON responses.
- **Health Check** – `/health` endpoint always returns `200 OK`, used by orchestrators.
- **Structured Logging** – All requests and errors are logged to `stdout` with severity levels.
- **Bash Diagnostics** – `server-info.sh` collects system metrics, Docker status, and verifies HTTP service availability.
- **Containerisation** – `Dockerfile`, `HEALTHCHECK`, and `.dockerignore`.
- **Docker Compose** – Single‑command local environment with health checks and restart policy.
- **CI Pipeline** – GitHub Actions runs linters, tests, builds the image, and verifies container health.
- **Ansible** – Roles for installing Docker and deploying the application on Ubuntu servers.
- **Makefile** – Handy shortcuts for every common task.

## Technology Stack

| Component       | Technology                           |
|-----------------|--------------------------------------|
| API Framework   | Flask 3.0 (Python 3.12)              |
| Testing         | Pytest + Flask test client           |
| Container       | Docker, Docker Compose               |
| CI/CD           | GitHub Actions                       |
| Automation      | Ansible 9+ (roles, handlers, vars)   |
| Diagnostics     | Bash (curl)                          |
| Logging         | Python `logging`                     |

## Prerequisites

- **Local Development**: `python` 3.12+, `pip`, `curl`, `shellcheck`, `flake8`, `ssh`
- **Docker & Compose**: Docker Engine ≥24, Docker Compose v2 (or plugin)
- **Ansible** (for deployment): control node with Ansible 9+, target Ubuntu 22.04/24.04 server with SSH access

## Quick Start

### Setup

#### Change your server variables

1. In `ansible/inventory.ini` change `ansible_host` and `ansible_user`
2. In `Makefile` change `SSH_TARGET`

### Local Development

```bash
# Install Python dependencies
make install
# or manually: pip install -r app/requirements.txt

# Run the application
make run
# or: python app/main.py

# In another terminal, call the health endpoint
curl http://localhost:5000/health
```

### Using Docker Compose

```bash
# Build and start the container
make compose-up
# or: docker compose up -d

# Verify it's running
curl http://localhost:5000

# View logs
make compose-logs

# Stop everything
make compose-down
```

## API Reference

All endpoints return `application/json`. The API stores users in memory – data is lost when the application restarts.

### Endpoints

| Method | URL                     | Description                              | Request Body                 | Response                                 |
|--------|-------------------------|------------------------------------------|------------------------------|------------------------------------------|
| GET    | `/`                     | Welcome message                          | –                            | `{"message":"Hello, World!"}`            |
| GET    | `/health`               | Liveness/readiness probe                 | –                            | `{"status":"ok"}`                        |
| GET    | `/api/users`            | List all users                           | –                            | `{"users":[...]}`                        |
| POST   | `/api/users`            | Create a new user                        | `{"name":<string>}`          | `{"id":<int>, "name":<string>}`          |
| GET    | `/api/users/<id>`       | Retrieve a user by ID                    | –                            | `{"id":<int>, "name":<string>}`          |
| DELETE | `/api/users/<id>`       | Delete a user                            | –                            | `{"message":"User deleted"}`             |

### Example `curl` Commands

```bash
# Root endpoint
curl http://localhost:5000/

# Health check
curl http://localhost:5000/health

# Get all users (initially empty)
curl http://localhost:5000/api/users

# Create a user
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice"}'

# Create another user
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Bob"}'

# Get user with ID 1
curl http://localhost:5000/api/users/1

# Delete user with ID 1
curl -X DELETE http://localhost:5000/api/users/1

# Try to get deleted user – returns 404
curl http://localhost:5000/api/users/1
```

## Testing

We use `pytest` with the Flask test client. **At least 5 tests** cover success and error cases.

```bash
# Run all tests
make test
# or: pytest app/tests/ -v

# Expected output: PASSED
```

## Diagnostics Script (Bash)

`scripts/server-info.sh` provides a comprehensive server health report.

### Usage

```bash
# Show help
./scripts/server-info.sh --help

# Collect system info only (no HTTP checks)
./scripts/server-info.sh

# Check one or more HTTP endpoints
./scripts/server-info.sh http://localhost:5000/health http://example.com/health

# Specify custom log file
./scripts/server-info.sh --log /tmp/my.log http://localhost:5000/health
```

### Remote usage

```bash
ssh ${ssh_target} 'bash -s' -- ${args} < ./scripts/server-info.sh
```

### What it does

- **System information**: hostname, OS, kernel, uptime
- **Resources**: CPU cores + load average, RAM usage (used/total + %), disk usage for `/`
- **Docker**: lists running containers if Docker is installed and accessible
- **HTTP checks**: measures response time, HTTP status, and fails if any endpoint returns non‑2xx or cannot be reached
- **Logging**: writes everything to a timestamped log file (default `/tmp/server-info-<timestamp>.log`) and to the console
- **Exit code**: `0` if all services are healthy (or no URLs given), `1` otherwise

### Example output

```text
=== Server Diagnostics ===
Date:     2026-04-28 12:34:56
Hostname: my-server
OS:       Ubuntu 24.04 LTS
Kernel:   6.8.0-51-generic
Uptime:   2 days, 4:30

=== Resources ===
CPU:      4 cores, load average: 0.15, 0.10, 0.05
RAM:      1.2Gi / 3.8Gi (31%)
Disk /:   15G / 50G (30%)

=== Docker ===
CONTAINER ID   IMAGE                     STATUS
abc123def456   simple-app:latest         Up 2 hours (healthy)

=== Service Health Checks ===
[OK]   http://localhost:5000/health (200, 8ms)
[FAIL] http://localhost:8080/health (connection error)

Result: 1/2 services healthy
```

## Docker & Docker Compose Details

### Dockerfile Highlights

- **Python 3.12‑slim** base image (small footprint)
- **Healthcheck** – `curl` probes `/health` every 30s
- **Gunicorn** as production WSGI server (3 workers)

### `.dockerignore`

Excludes unnecessary files (tests, ansible, `.git`, etc.) to keep the image lean.

### Docker Compose (`docker-compose.yml`)

```yaml
services:
  app:
    build: .
    ports: ["5000:5000"]
    environment:
      - FLASK_ENV=production
    healthcheck: { test: ["CMD", "curl", "-f", "http://localhost:5000/health"] }
    restart: unless-stopped
```

**Common commands** via Makefile:

- `make docker-build` – build the image
- `make docker-run` – run a standalone container (detached)
- `make compose-up` – start with Compose
- `make compose-down` – stop and remove containers
- `make compose-logs` – follow logs

## Ansible Automation

The `ansible/` directory contains a complete playbook to deploy the application on a fresh Ubuntu server.

### Inventory & Variables

**Inventory file** (`ansible/inventory.ini`):

```ini
[webservers]
app-server-1 ansible_host=your_user ansible_user=your_user
```

**Playbook variables** (defined in `playbook.yml`):

| Variable       | Default value          | Description                     |
|----------------|------------------------|---------------------------------|
| `app_port`     | `5000`                 | Host port to expose             |
| `docker_image` | `simple-app:latest`    | Docker image name/tag           |
| `app_dir`      | `/opt/simple-app`      | Deployment directory on server  |

### What the Playbook Does

1. **Role `docker`**:
   - Updates apt cache
   - Installs Docker CE, Docker Compose plugin
   - Starts and enables Docker daemon
   - Adds current user to `docker` group (with a handler to restart Docker)
2. **Role `app`**:
   - Creates `app_dir`
   - Copies application source code (or uses `git clone` – adjust as needed)
   - Deploys `docker-compose.yml` via a Jinja2 template
   - Runs `docker compose up -d`
   - Waits for the container health endpoint (`/health`) to return 200

### Running the Playbook

```bash
# Syntax check
make ansible-check

# Dry run (no changes)
make ansible-dry

# Full deployment
make ansible-run
```

> **Note**: For a production setup, you should push the Docker image to a registry (e.g., Docker Hub) and pull it on the target server instead of copying the source code. The current role copies the whole project – this is convenient for development but not for large‑scale deployments.

## GitHub Actions CI/CD

The workflow (`.github/workflows/build.yml`) triggers on `push` or `pull_request` to the `main` branch.

**Pipeline stages**:

1. **Checkout** code
2. **Setup Python 3.12**
3. **Install dependencies** (`pip install -r app/requirements.txt`)
4. **Lint Bash scripts** (shellcheck)
5. **Run Pytest** – ensures all tests pass
6. **Build Docker image** (`docker build -t simple-app:latest .`)
7. **Test container health** – run container, wait 5s, call `/health`, then clean up

If any step fails, the pipeline marks the commit as broken.

## Makefile Commands

The provided `Makefile` simplifies daily tasks. Run `make help` to see all targets:

| Command                     | Description                                   |
|-----------------------------|-----------------------------------------------|
| `make help`                 | Show this help message                        |
| `make install`              | Install Python dependencies (pip)             |
| `make lint`                 | Run flake8 (Python) and shellcheck (Bash)     |
| `make test`                 | Execute pytest                                |
| `make run`                  | Start Flask development server                |
| `make server-info`          | Run diagnostics script (no URL checks)        |
| `make server-info-health`   | Run diagnostics script (with healthcheck)     |
| `make docker-build`         | Build Docker image                            |
| `make docker-run`           | Run a standalone container                    |
| `make compose-up`           | Start services with Docker Compose            |
| `make compose-down`         | Stop Docker Compose services                  |
| `make compose-logs`         | Tail logs from Compose                        |
| `make ansible-check`        | Validate Ansible playbook syntax              |
| `make ansible-dry`          | Dry‑run Ansible playbook                      |
| `make ansible-run`          | Execute Ansible playbook (deploy)             |

## Contributing & License

**License**: MIT (see [LICENSE](LICENSE) file if included).
