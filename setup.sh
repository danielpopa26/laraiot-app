#!/usr/bin/env bash
set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== LaraIoT Environment Setup ===${NC}"

# 1. Verificare fisier .env
if [ ! -f .env ]; then
    echo -e "${GREEN}[+] Creare .env...${NC}"
    cp .env.example .env
fi

# 2. Configurare Mosquitto daca lipseste
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

# 3. Pornire servicii de baza (fara workerii dependenti de DB)
echo -e "${GREEN}[+] Pornire containere principale...${NC}"
docker compose up -d --build mariadb mosquitto app webserver

# 4. Configurare permisiuni storage si cache din interiorul containerului
echo -e "${GREEN}[+] Configurare permisiuni storage si cache...${NC}"
docker compose exec -u root app sh -c "mkdir -p storage/framework/{sessions,views,cache} bootstrap/cache && chmod -R 777 storage bootstrap/cache"

# 5. Instalare dependente Composer
echo -e "${GREEN}[+] Instalare dependente Composer...${NC}"
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

# 6. Generare cheie aplicatie
echo -e "${GREEN}[+] Generare cheie aplicatie...${NC}"
docker compose exec app php artisan key:generate --ansi

# 7. Asteptare initializare completa MariaDB
echo -e "${GREEN}[+] Asteptare pornire MariaDB...${NC}"
sleep 10

# 8. Rulare comanda de instalare LaraIoT
echo -e "${GREEN}[+] Rulare comanda de instalare LaraIoT...${NC}"
docker compose exec app php artisan laraiot:install --ui --force

# 9. Rulare migratii baza de date
echo -e "${GREEN}[+] Rulare migratii in MariaDB...${NC}"
docker compose exec app php artisan migrate --force

# 10. Compilare frontend
echo -e "${GREEN}[+] Compilare frontend (Vite & Vue)...${NC}"
docker compose exec app npm install
docker compose exec app npm run build

# 11. Pornire servicii dependente de DB (Reverb & MQTT Listener)
echo -e "${GREEN}[+] Pornire server WebSocket (Reverb) si MQTT Listener...${NC}"
docker compose up -d reverb mqtt-listener
docker compose restart reverb mqtt-listener

echo -e "\n${GREEN}=== LaraIoT este gata de utilizare! ===${NC}"
echo -e "Interfata Web:        ${BLUE}http://localhost:8000/laraiot${NC}"
echo -e "Broker MQTT:          ${BLUE}mqtt://localhost:1883${NC}"
echo -e "WebSocket (Reverb):   ${BLUE}ws://localhost:8085${NC}"