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
echo [+] Building and starting Docker containers...
docker compose up -d --build

echo.
echo [+] Waiting for MariaDB to initialize...
timeout /t 10 /nobreak >nul

echo.
echo [+] Generating application key...
docker compose exec app php artisan key:generate --force

echo.
echo [+] Updating Composer dependencies...
docker compose exec app composer update --no-interaction --prefer-dist --optimize-autoloader

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
echo [+] Restarting MQTT Listener worker...
docker compose restart mqtt-listener

echo.
echo ==================================================
echo  LaraIoT is ready to use!
echo  Web Interface:     http://localhost:8000/laraiot
echo  MQTT Broker:       mqtt://localhost:1883
echo  WebSocket Server:  ws://localhost:8085
echo ==================================================
pause