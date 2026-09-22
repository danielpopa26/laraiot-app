@echo off
setlocal enabledelayedexpansion

echo ==================================================
echo        LaraIoT Environment Modular Setup (CMD)
echo ==================================================

set DEFAULT_HOST=localhost
set /p CHOSEN_HOST="Enter host/IP for LAN & IoT access [%DEFAULT_HOST%]: "
if "%CHOSEN_HOST%"=="" set CHOSEN_HOST=%DEFAULT_HOST%

if not exist .env (
    echo [+] Creating .env from .env.example...
    copy .env.example .env >nul
)

echo.
echo [+] Starting core containers...
docker compose up -d --build mariadb mqtt-broker app webserver

echo.
echo [+] Installing Composer dependencies...
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

echo.
echo [+] Generating application key...
docker compose exec app php artisan key:generate --force

echo.
echo [+] Waiting for database initialization...
timeout /t 10 /nobreak >nul

echo.
echo [+] Running LaraIoT installation...
docker compose exec app php artisan laraiot:install --ui --force

echo.
echo [+] Running database migrations...
docker compose exec app php artisan migrate --force

echo.
echo [+] Installing and building frontend assets...
docker compose exec app npm install
docker compose exec app npm run build

echo.
echo [+] Starting Reverb and MQTT Listener...
docker compose up -d reverb mqtt-listener

echo.
echo ==================================================
echo  LaraIoT is ready to use!
echo  Local Web UI:         http://localhost:8000/laraiot
echo  LAN Web UI:           http://%CHOSEN_HOST%:8000/laraiot
echo  MQTT Broker for IoT:  mqtt://%CHOSEN_HOST%:1883
echo  WebSocket Server:     ws://%CHOSEN_HOST%:8085
echo ==================================================
pause