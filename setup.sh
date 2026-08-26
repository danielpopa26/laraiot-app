#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== LaraIoT Environment Setup ===${NC}"

# 1. Check .env file
if [ ! -f .env ]; then
    echo -e "${GREEN}[+] Creating .env file from .env.example...${NC}"
    cp .env.example .env
fi

# 2. Configure Mosquitto if missing
mkdir -p .docker/mosquitto/config
if [ ! -f .docker/mosquitto/config/mosquitto.conf ]; then
    echo -e "${GREEN}[+] Configuring Mosquitto broker...${NC}"
    cat << 'EOF' > .docker/mosquitto/config/mosquitto.conf
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF
fi

# 3. Start core services (without DB-dependent workers)
echo -e "${GREEN}[+] Starting core Docker containers...${NC}"
docker compose up -d --build mariadb mqtt-broker app webserver

# 4. Set storage and cache permissions inside container
echo -e "${GREEN}[+] Setting storage and cache directory permissions...${NC}"
docker compose exec -u root app sh -c "mkdir -p storage/framework/{sessions,views,cache} bootstrap/cache && chmod -R 777 storage bootstrap/cache"

# 5. Install Composer dependencies
echo -e "${GREEN}[+] Installing Composer dependencies...${NC}"
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

# 6. Generate application key
echo -e "${GREEN}[+] Generating application key...${NC}"
docker compose exec app php artisan key:generate --ansi

# 7. Wait for MariaDB initialization
echo -e "${GREEN}[+] Waiting for MariaDB to initialize...${NC}"
sleep 10

# 8. Run LaraIoT installer
echo -e "${GREEN}[+] Running LaraIoT installation...${NC}"
docker compose exec app php artisan laraiot:install --ui --force

# 9. Run database migrations
echo -e "${GREEN}[+] Running database migrations in MariaDB...${NC}"
docker compose exec app php artisan migrate --force

# 10. Compile frontend assets
echo -e "${GREEN}[+] Building frontend assets (Vite & Vue)...${NC}"
docker compose exec app npm install
docker compose exec app npm run build

# 11. Start DB-dependent services (Reverb & MQTT Listener)
echo -e "${GREEN}[+] Starting WebSocket server (Reverb) and MQTT Listener...${NC}"
docker compose up -d reverb mqtt-listener

echo -e "\n${GREEN}=== LaraIoT is ready to use! ===${NC}"
echo -e "Web Interface:        ${BLUE}http://localhost:8000/laraiot${NC}"
echo -e "MQTT Broker:          ${BLUE}mqtt://localhost:1883${NC}"
echo -e "WebSocket (Reverb):   ${BLUE}ws://localhost:8085${NC}"