#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=== LaraIoT Environment Setup ===${NC}"

# 1. Verificare fisier .env
if [ ! -f .env ]; then
    echo -e "${GREEN}[+] Creare .env...${NC}"
    cp .env.example .env
fi

# 2. Configurare Mosquitto
mkdir -p .docker/mosquitto/config
if [ ! -f .docker/mosquitto/config/mosquitto.conf ]; then
    echo -e "${GREEN}[+] Configurare broker Mosquitto...${NC}"
    cat << 'EOF' > .docker/mosquitto/config/mosquitto.conf
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
EOF
fi

# 3. Build containere Docker
echo -e "${GREEN}[+] Pornire containere Docker...${NC}"
docker compose up -d --build

# 4. Instalare pachete PHP prin container
echo -e "${GREEN}[+] Instalare dependente Composer...${NC}"
docker compose exec app composer update --no-interaction --prefer-dist --optimize-autoloader

# 5. Generare APP_KEY
echo -e "${GREEN}[+] Generare cheie aplicatie...${NC}"
docker compose exec app php artisan key:generate --ansi

# 6. Rulare comanda de instalare pachet LaraIoT
echo -e "${GREEN}[+] Rulare comanda de instalare LaraIoT...${NC}"
docker compose exec app php artisan laraiot:install --ui --force

# 7. Rulare migratii
echo -e "${GREEN}[+] Rulare migratii in MariaDB...${NC}"
docker compose exec app php artisan migrate --force

# 8. Compilare frontend
echo -e "${GREEN}[+] Compilare frontend (Vite & Vue) in container...${NC}"
docker compose exec app npm install
docker compose exec app npm run build

# 9. Setare permisiuni
docker compose exec app chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

echo -e "\n${GREEN}=== LaraIoT este gata de utilizare! ===${NC}"
echo -e "Interfata Web:        ${BLUE}http://localhost:8080/laraiot${NC}"
echo -e "Broker MQTT:          ${BLUE}mqtt://localhost:1883${NC}"
echo -e "WebSocket (Reverb):   ${BLUE}ws://localhost:8085${NC}"