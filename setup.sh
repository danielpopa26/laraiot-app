#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}        LaraIoT Environment Modular Setup         ${NC}"
echo -e "${CYAN}==================================================${NC}"

# Detectare date de retea
DETECTED_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
DETECTED_IP=${DETECTED_IP:-"127.0.0.1"}
DETECTED_MAC=$(ip link 2>/dev/null | awk '/ether/ {print $2; exit}' || echo "N/A")
DETECTED_HOST="$(hostname 2>/dev/null || echo "laraiot-server").local"

echo -e "\n${BLUE}[i] Network Diagnosis:${NC}"
echo -e "    - Detected LAN IP:  ${GREEN}${DETECTED_IP}${NC}"
echo -e "    - Host MAC Address: ${GREEN}${DETECTED_MAC}${NC}"
echo -e "    - Local Hostname:   ${GREEN}${DETECTED_HOST}${NC}"
echo -e "    ${YELLOW}Tip: A Static IP or DHCP Reservation on your router is recommended for IoT stability.${NC}"

echo -e "\n${BLUE}[1/4] Network Access Host:${NC}"
echo -e "  1) Use detected IP (${DETECTED_IP})"
echo -e "  2) Enter custom Static IP"
echo -e "  3) Use local hostname (${DETECTED_HOST})"
echo -e "  4) Localhost only (127.0.0.1)"
read -p "Select option [1]: " NET_OPT
NET_OPT=${NET_OPT:-1}

case $NET_OPT in
    2)
        read -p "Enter custom Static IP: " CHOSEN_HOST
        ;;
    3)
        CHOSEN_HOST="$DETECTED_HOST"
        ;;
    4)
        CHOSEN_HOST="localhost"
        ;;
    *)
        CHOSEN_HOST="$DETECTED_IP"
        ;;
esac

echo -e "\n${BLUE}[2/4] Database Configuration:${NC}"
echo -e "  1) Deploy local MariaDB in Docker (Default)"
echo -e "  2) Connect to an external Database server (VM / Remote)"
read -p "Select option [1]: " DB_OPT
DB_OPT=${DB_OPT:-1}

USE_LOCAL_DB=true
if [ "$DB_OPT" == "2" ]; then
    USE_LOCAL_DB=false
    read -p "Database Host: " EXT_DB_HOST
    read -p "Database Port [3306]: " EXT_DB_PORT
    EXT_DB_PORT=${EXT_DB_PORT:-3306}
    read -p "Database Name [laraiot]: " EXT_DB_NAME
    EXT_DB_NAME=${EXT_DB_NAME:-laraiot}
    read -p "Database User [laraiot]: " EXT_DB_USER
    EXT_DB_USER=${EXT_DB_USER:-laraiot}
    read -p "Database Password: " EXT_DB_PASS
fi

echo -e "\n${BLUE}[3/4] MQTT Broker Configuration:${NC}"
echo -e "  1) Deploy local Mosquitto broker in Docker (Default)"
echo -e "  2) Connect to an external MQTT Broker (VM / Home Assistant)"
read -p "Select option [1]: " MQTT_OPT
MQTT_OPT=${MQTT_OPT:-1}

USE_LOCAL_MQTT=true
if [ "$MQTT_OPT" == "2" ]; then
    USE_LOCAL_MQTT=false
    read -p "MQTT Host: " EXT_MQTT_HOST
    read -p "MQTT Port [1883]: " EXT_MQTT_PORT
    EXT_MQTT_PORT=${EXT_MQTT_PORT:-1883}
    read -p "MQTT Username (optional): " EXT_MQTT_USER
    read -p "MQTT Password (optional): " EXT_MQTT_PASS
fi

echo -e "\n${BLUE}[4/4] WebSocket Server (Laravel Reverb):${NC}"
echo -e "  1) Deploy local Reverb server in Docker (Default)"
echo -e "  2) Connect to an external WebSocket server (VM / Dedicated)"
read -p "Select option [1]: " REVERB_OPT
REVERB_OPT=${REVERB_OPT:-1}

USE_LOCAL_REVERB=true
if [ "$REVERB_OPT" == "2" ]; then
    USE_LOCAL_REVERB=false
    read -p "External Reverb Host/IP: " EXT_REVERB_HOST
    read -p "External Reverb Port [8085]: " EXT_REVERB_PORT
    EXT_REVERB_PORT=${EXT_REVERB_PORT:-8085}
fi

# Copiere initiala .env daca nu exista
if [ ! -f .env ]; then
    echo -e "\n${GREEN}[+] Creating .env from .env.example...${NC}"
    cp .env.example .env
fi

# Functie sigura de actualizare linie cheie-valoare in .env
update_env() {
    local key="$1"
    local value="$2"
    if grep -q "^${key}=" .env; then
        sed -i "s|^${key}=.*|${key}=${value}|g" .env
    else
        echo "${key}=${value}" >> .env
    fi
}

# Aplicare configuratii de retea
update_env "APP_URL" "http://${CHOSEN_HOST}:8000"

# Aplicare Database
if [ "$USE_LOCAL_DB" = true ]; then
    update_env "DB_HOST" "mariadb"
    update_env "DB_PORT" "3306"
else
    update_env "DB_HOST" "$EXT_DB_HOST"
    update_env "DB_PORT" "$EXT_DB_PORT"
    update_env "DB_DATABASE" "$EXT_DB_NAME"
    update_env "DB_USERNAME" "$EXT_DB_USER"
    update_env "DB_PASSWORD" "$EXT_DB_PASS"
fi

# Aplicare MQTT
if [ "$USE_LOCAL_MQTT" = true ]; then
    update_env "LARAIOT_MQTT_HOST" "mqtt-broker"
    update_env "LARAIOT_MQTT_PORT" "1883"
    mkdir -p .docker/mosquitto/config
    if [ ! -f .docker/mosquitto/config/mosquitto.conf ]; then
        cat << 'EOF' > .docker/mosquitto/config/mosquitto.conf
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF
    fi
else
    update_env "LARAIOT_MQTT_HOST" "$EXT_MQTT_HOST"
    update_env "LARAIOT_MQTT_PORT" "$EXT_MQTT_PORT"
    if [ -n "$EXT_MQTT_USER" ]; then
        update_env "LARAIOT_MQTT_AUTH_TYPE" "credentials"
        update_env "LARAIOT_MQTT_USERNAME" "$EXT_MQTT_USER"
        update_env "LARAIOT_MQTT_PASSWORD" "$EXT_MQTT_PASS"
    else
        update_env "LARAIOT_MQTT_AUTH_TYPE" "none"
    fi
fi

# Aplicare WebSocket (Reverb)
if [ "$USE_LOCAL_REVERB" = true ]; then
    update_env "REVERB_HOST" "reverb"
    update_env "REVERB_SERVER_HOST" "reverb"
    update_env "REVERB_PORT" "8080"
    update_env "VITE_REVERB_HOST" "\"${CHOSEN_HOST}\""
    update_env "VITE_REVERB_PORT" "8085"
else
    update_env "REVERB_HOST" "$EXT_REVERB_HOST"
    update_env "REVERB_SERVER_HOST" "$EXT_REVERB_HOST"
    update_env "REVERB_PORT" "$EXT_REVERB_PORT"
    update_env "VITE_REVERB_HOST" "\"${EXT_REVERB_HOST}\""
    update_env "VITE_REVERB_PORT" "$EXT_REVERB_PORT"
fi

# Determinare lista containere Docker de pornit
CORE_SERVICES="app webserver"
[ "$USE_LOCAL_DB" = true ] && CORE_SERVICES="mariadb $CORE_SERVICES"
[ "$USE_LOCAL_MQTT" = true ] && CORE_SERVICES="mqtt-broker $CORE_SERVICES"

echo -e "\n${GREEN}[+] Starting selected core containers (${CORE_SERVICES})...${NC}"
docker compose up -d --build $CORE_SERVICES

echo -e "${GREEN}[+] Setting storage and cache directory permissions...${NC}"
docker compose exec -u root app sh -c "mkdir -p storage/framework/{sessions,views,cache} bootstrap/cache && chmod -R 777 storage bootstrap/cache"

echo -e "${GREEN}[+] Installing Composer dependencies...${NC}"
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

echo -e "${GREEN}[+] Generating application key...${NC}"
docker compose exec app php artisan key:generate --ansi

if [ "$USE_LOCAL_DB" = true ]; then
    echo -e "${GREEN}[+] Waiting for local MariaDB to initialize...${NC}"
    sleep 10
fi

echo -e "${GREEN}[+] Running LaraIoT installer...${NC}"
docker compose exec app php artisan laraiot:install --ui --force

echo -e "${GREEN}[+] Running database migrations...${NC}"
docker compose exec app php artisan migrate --force

echo -e "${GREEN}[+] Building frontend assets (Vite & Vue)...${NC}"
docker compose exec app npm install
docker compose exec app npm run build

WORKER_SERVICES="mqtt-listener"
[ "$USE_LOCAL_REVERB" = true ] && WORKER_SERVICES="reverb $WORKER_SERVICES"

echo -e "${GREEN}[+] Starting worker containers (${WORKER_SERVICES})...${NC}"
docker compose up -d $WORKER_SERVICES

echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN} LaraIoT is ready to use!${NC}"
echo -e " Local Web UI:         ${BLUE}http://localhost:8000/laraiot${NC}"
echo -e " LAN Web UI:           ${BLUE}http://${CHOSEN_HOST}:8000/laraiot${NC}"
if [ "$USE_LOCAL_MQTT" = true ]; then
    echo -e " MQTT Broker for IoT:  ${BLUE}mqtt://${CHOSEN_HOST}:1883${NC}"
else
    echo -e " MQTT Broker for IoT:  ${BLUE}mqtt://${EXT_MQTT_HOST}:${EXT_MQTT_PORT}${NC}"
fi
if [ "$USE_LOCAL_REVERB" = true ]; then
    echo -e " WebSocket (Reverb):   ${BLUE}ws://${CHOSEN_HOST}:8085${NC}"
fi
echo -e "\n${CYAN}[i] Network Checklist:${NC}"
echo -e "    1. If using DHCP, reserve IP ${YELLOW}${CHOSEN_HOST}${NC} for MAC ${YELLOW}${DETECTED_MAC}${NC} in your router."
echo -e "    2. Ensure inbound firewall allows ports: 8000 (HTTP), 1883 (MQTT), 8085 (WS)."
echo -e "${GREEN}==================================================${NC}"