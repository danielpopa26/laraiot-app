# LaraIoT Starter Application - Windows Setup Script (PowerShell)
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "      LaraIoT Docker Setup for Windows           " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Copiere fisier de mediu .env daca nu exista
if (-not (Test-Path ".env")) {
    Write-Host "[+] Creating .env file from .env.example..." -ForegroundColor Green
    Copy-Item ".env.example" ".env"
} else {
    Write-Host "[i] .env file already exists. Skipping copy." -ForegroundColor Yellow
}

# 2. Pornire containere Docker
Write-Host "`n[+] Building and starting Docker containers..." -ForegroundColor Green
docker compose up -d --build

# 3. Asteptare initializare MariaDB (10 secunde)
Write-Host "`n[+] Waiting for MariaDB to initialize..." -ForegroundColor Green
Start-Sleep -Seconds 10

# 4. Generare cheie aplicatie daca nu exista
Write-Host "`n[+] Generating application key..." -ForegroundColor Green
docker compose exec app php artisan key:generate --force

# 5. Instalare/Update dependente Composer
Write-Host "`n[+] Updating Composer dependencies..." -ForegroundColor Green
docker compose exec app composer update --no-interaction --prefer-dist --optimize-autoloader

# 6. Publicare componente si rulare instalare LaraIoT
Write-Host "`n[+] Running LaraIoT installation..." -ForegroundColor Green
docker compose exec app php artisan laraiot:install --ui --force

# 7. Rulare migratii baza de date
Write-Host "`n[+] Running database migrations..." -ForegroundColor Green
docker compose exec app php artisan migrate --force

# 8. Instalare si compilare frontend Vite
Write-Host "`n[+] Installing and building frontend assets..." -ForegroundColor Green
docker compose exec app npm install
docker compose exec app npm run build

# 9. Repornire listener MQTT
Write-Host "`n[+] Restarting MQTT Listener worker..." -ForegroundColor Green
docker compose restart mqtt-listener

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " LaraIoT is ready to use!" -ForegroundColor Green
Write-Host " Web Interface:     http://localhost:8000/laraiot" -ForegroundColor White
Write-Host " MQTT Broker:       mqtt://localhost:1883" -ForegroundColor White
Write-Host " WebSocket Server:  ws://localhost:8085" -ForegroundColor White
Write-Host "==================================================" -ForegroundColor Cyan