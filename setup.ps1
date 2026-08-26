$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      LaraIoT Docker Setup for Windows           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Check .env file
if (-not (Test-Path ".env")) {
    Write-Host "[+] Creating .env file from .env.example..." -ForegroundColor Green
    Copy-Item ".env.example" ".env"
} else {
    Write-Host "[i] .env file already exists. Skipping copy." -ForegroundColor Yellow
}

# 2. Start core services (without DB-dependent workers)
Write-Host "`n[+] Starting core Docker containers..." -ForegroundColor Green
docker compose up -d --build mariadb mqtt-broker app webserver

# 3. Install Composer dependencies
Write-Host "`n[+] Installing Composer dependencies..." -ForegroundColor Green
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

# 4. Generate application key
Write-Host "`n[+] Generating application key..." -ForegroundColor Green
docker compose exec app php artisan key:generate --force

# 5. Wait for MariaDB initialization
Write-Host "`n[+] Waiting for MariaDB to initialize..." -ForegroundColor Green
Start-Sleep -Seconds 10

# 6. Run LaraIoT installation
Write-Host "`n[+] Running LaraIoT installation..." -ForegroundColor Green
docker compose exec app php artisan laraiot:install --ui --force

# 7. Run database migrations
Write-Host "`n[+] Running database migrations..." -ForegroundColor Green
docker compose exec app php artisan migrate --force

# 8. Compile Vite frontend assets
Write-Host "`n[+] Installing and building frontend assets..." -ForegroundColor Green
docker compose exec app npm install
docker compose exec app npm run build

# 9. Start DB-dependent services (Reverb and MQTT Listener)
Write-Host "`n[+] Starting WebSocket server (Reverb) and MQTT Listener..." -ForegroundColor Green
docker compose up -d reverb mqtt-listener

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " LaraIoT is ready to use!" -ForegroundColor Green
Write-Host " Web Interface:     http://localhost:8000/laraiot" -ForegroundColor White
Write-Host " MQTT Broker:       mqtt://localhost:1883" -ForegroundColor White
Write-Host " WebSocket Server:  ws://localhost:8085" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan