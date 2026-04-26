#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME=$(basename "$0")
LOG_FILE=$(printf "/tmp/server-info-%s.log" "$(date +%Y%m%d-%H%M%S)")

help() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS] [URL...]

Collects server diagnostics and optionally checks health of HTTP services.

Options:
  --help          Show this help message
  --log FILE      Write log to FILE (default: /tmp/server-info-(date).log)

Arguments:
  URL...          One or more HTTP/HTTPS endpoints to check.

Exit codes:
  0 - All services healthy (or no URLs given)
  1 - At least one service is unhealthy

Examples:
  $SCRIPT_NAME
  $SCRIPT_NAME http://localhost:5000/health
  $SCRIPT_NAME --log /var/log/mycheck.log http://example.com/health
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

check_deps() {
    local deps=("curl" "docker")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            log "ERROR: Required dependency '$dep' not found."
            exit 1
        fi
    done
}

system_info() {
    log "=== Server Diagnostics ==="
    log "Date:     $(date '+%Y-%m-%d %H:%M:%S')"
    log "Hostname: $(hostname)"
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        log "OS:       $PRETTY_NAME"
    else
        log "OS:       Unknown"
    fi
    log "Kernel:   $(uname -r)"
    log "Uptime:   $(uptime -p | sed 's/up //')"
}

resources_info() {
    log ""
    log "=== Resources ==="
    # CPU
    if command -v nproc &> /dev/null; then
        cores=$(nproc)
    else
        cores=$(grep -c ^processor /proc/cpuinfo)
    fi
    load=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //')
    log "CPU:      $cores cores, load average: $load"
    # RAM
    if command -v free &> /dev/null; then
        mem_total=$(free -h | awk '/^Mem:/ {print $2}')
        mem_used=$(free -h | awk '/^Mem:/ {print $3}')
        mem_percent=$(free | awk '/^Mem:/ {printf "%.0f", $3/$2 * 100}')
        log "RAM:      $mem_used / $mem_total ($mem_percent%)"
    else
        log "RAM:      N/A (free not available)"
    fi
    # Disk
    disk_info=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
    log "Disk /:   $disk_info"
}

docker_info() {
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log ""
        log "=== Docker ==="
        docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}" | head -10 | while read -r line; do
            log "$line"
        done
    else
        log ""
        log "=== Docker ==="
        log "Docker not running."
    fi
}

check_services() {
    local urls=("$@")
    if [ ${#urls[@]} -eq 0 ]; then
        return 0
    fi
    log ""
    log "=== Service Health Checks ==="
    local ok_count=0
    local total=${#urls[@]}
    for url in "${urls[@]}"; do
        start=$(date +%s%N)
        http_code=$(curl -o /dev/null -s -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
        end=$(date +%s%N)
        elapsed=$(( (end - start) / 1000000 )) # ms
        if [[ "$http_code" =~ ^2 ]]; then
            status="[OK]"
            message="$http_code, ${elapsed}ms"
            ((ok_count+=1))
        else
            status="[FAIL]"
            message="connection refused"
        fi
        log "$status $url ($message)"
    done
    log ""
    log "Result: $ok_count/$total services healthy"
    if [ $ok_count -eq "$total" ]; then
        return 0
    else
        return 1
    fi
}

main() {
    local urls=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                help
                exit 0
                ;;
            --log)
                LOG_FILE="$2"
                shift 2
                ;;
            --*)
                echo "Unknown option: $1"
                help
                exit 1
                ;;
            *)
                urls+=("$1")
                shift
                ;;
        esac
    done
    touch "$LOG_FILE"
    check_deps
    system_info
    resources_info
    docker_info
    check_services "${urls[@]}"
    exit $?
}

main "$@"
