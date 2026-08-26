@echo off
setlocal enabledelayedexpansion

echo ==================================================
echo       LaraIoT Docker Setup for Windows (CMD)
echo ==================================================

if not exist .env (
    echo [+] Creating .env file from .env.example...
    copy .env.example .env >nul
) else (
    echo [i] .env file already exists. Skipping copy.
)

echo.
echo [+] Building and starting core Docker containers...
docker compose up -d --build mariadb mosquitto app nginx

echo.
echo [+] Installing Composer dependencies...
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

echo.
echo [+] Generating application key...
docker compose exec app php artisan key:generate --force

echo.
echo [+] Waiting for MariaDB to initialize...
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
echo [+] Starting Reverb WebSocket and MQTT Listener...
docker compose up -d reverb mqtt-listener
docker compose restart reverb mqtt-listener

echo.
echo ==================================================
echo  LaraIoT is ready to use!
echo  Web Interface:     http://localhost:8000/laraiot
echo  MQTT Broker:       mqtt://localhost:1883
echo  WebSocket Server:  ws://localhost:8080
echo ==================================================
pause