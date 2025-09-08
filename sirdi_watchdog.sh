#!/bin/bash

# SIRDI Watchdog Script
# Monitors the health and status of the SIRDI system

SIRDI_DIR="/home/new/sirdi-project"
LOG_FILE="$SIRDI_DIR/watchdog.log"
PID_FILE="$SIRDI_DIR/watchdog.pid"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check if SIRDI is healthy
check_sirdi_health() {
    local health_status="HEALTHY"
    
    # Check if required files exist
    if [[ ! -f "$SIRDI_DIR/sirdi.pub" ]]; then
        health_status="UNHEALTHY - Missing public key"
    elif [[ ! -f "$SIRDI_DIR/sirdi.sec" ]]; then
        health_status="UNHEALTHY - Missing private key"
    elif [[ ! -f "$SIRDI_DIR/first_log.txt" ]]; then
        health_status="UNHEALTHY - Missing log files"
    fi
    
    # Check if signature verification works
    if [[ "$health_status" == "HEALTHY" ]]; then
        cd "$SIRDI_DIR"
        if ! signify-openbsd -V -p sirdi.pub -m first_log.txt >/dev/null 2>&1; then
            health_status="UNHEALTHY - Signature verification failed"
        fi
    fi
    
    echo "$health_status"
}

# Function to start watchdog
start_watchdog() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log_message "Watchdog is already running (PID: $(cat "$PID_FILE"))"
        exit 1
    fi
    
    echo $$ > "$PID_FILE"
    log_message "🐕 SIRDI Watchdog started (PID: $$)"
    
    while true; do
        health=$(check_sirdi_health)
        log_message "Health check: $health"
        
        if [[ "$health" != "HEALTHY" ]]; then
            log_message "⚠️  ALERT: $health"
            # Could add notification or recovery actions here
        fi
        
        sleep 30  # Check every 30 seconds
    done
}

# Function to stop watchdog
stop_watchdog() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            log_message "🐕 SIRDI Watchdog stopped (PID: $pid)"
        else
            log_message "Watchdog process not found, cleaning up PID file"
            rm -f "$PID_FILE"
        fi
    else
        log_message "Watchdog is not running"
    fi
}

# Function to show status
show_status() {
    if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "🐕 SIRDI Watchdog is running (PID: $(cat "$PID_FILE"))"
        echo "Health status: $(check_sirdi_health)"
    else
        echo "🐕 SIRDI Watchdog is not running"
        echo "Health status: $(check_sirdi_health)"
    fi
}

# Main script logic
case "${1:-start}" in
    start)
        start_watchdog
        ;;
    stop)
        stop_watchdog
        ;;
    restart)
        stop_watchdog
        sleep 2
        start_watchdog
        ;;
    status)
        show_status
        ;;
    check)
        echo "$(check_sirdi_health)"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|check}"
        echo "  start   - Start the watchdog (default)"
        echo "  stop    - Stop the watchdog"
        echo "  restart - Restart the watchdog"
        echo "  status  - Show watchdog status"
        echo "  check   - Check SIRDI health once"
        exit 1
        ;;
esac
