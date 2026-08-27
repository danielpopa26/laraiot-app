$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "        LaraIoT Environment Modular Setup         " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# Detectare date de retea
$NetAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$DetectedMac = if ($NetAdapter) { $NetAdapter.MacAddress } else { "N/A" }
$DetectedIp = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
if (-not $DetectedIp) { $DetectedIp = "127.0.0.1" }
$DetectedHost = "$($env:COMPUTERNAME.ToLower()).local"

Write-Host "`n[i] Network Diagnosis:" -ForegroundColor Cyan
Write-Host "    - Detected LAN IP:  $DetectedIp" -ForegroundColor Green
Write-Host "    - Host MAC Address: $DetectedMac" -ForegroundColor Green
Write-Host "    - Local Hostname:   $DetectedHost" -ForegroundColor Green
Write-Host "    Tip: A Static IP or DHCP Reservation on your router is recommended for IoT stability." -ForegroundColor Yellow

Write-Host "`n[1/4] Network Access Host:" -ForegroundColor Cyan
Write-Host "  1) Use detected IP ($DetectedIp)"
Write-Host "  2) Enter custom Static IP"
Write-Host "  3) Use local hostname ($DetectedHost)"
Write-Host "  4) Localhost only (127.0.0.1)"
$NetOpt = Read-Host "Select option [1]"
if (-not $NetOpt) { $NetOpt = "1" }

switch ($NetOpt) {
    "2" { $ChosenHost = Read-Host "Enter custom Static IP" }
    "3" { $ChosenHost = $DetectedHost }
    "4" { $ChosenHost = "localhost" }
    Default { $ChosenHost = $DetectedIp }
}

Write-Host "`n[2/4] Database Configuration:" -ForegroundColor Cyan
Write-Host "  1) Deploy local MariaDB in Docker (Default)"
Write-Host "  2) Connect to an external Database server (VM / Remote)"
$DbOpt = Read-Host "Select option [1]"
if (-not $DbOpt) { $DbOpt = "1" }

$UseLocalDb = $true
if ($DbOpt -eq "2") {
    $UseLocalDb = $false
    $ExtDbHost = Read-Host "Database Host"
    $ExtDbPort = Read-Host "Database Port [3306]"
    if (-not $ExtDbPort) { $ExtDbPort = "3306" }
    $ExtDbName = Read-Host "Database Name [laraiot]"
    if (-not $ExtDbName) { $ExtDbName = "laraiot" }
    $ExtDbUser = Read-Host "Database User [laraiot]"
    if (-not $ExtDbUser) { $ExtDbUser = "laraiot" }
    $ExtDbPass = Read-Host "Database Password"
}

Write-Host "`n[3/4] MQTT Broker Configuration:" -ForegroundColor Cyan
Write-Host "  1) Deploy local Mosquitto broker in Docker (Default)"
Write-Host "  2) Connect to an external MQTT Broker (VM / Home Assistant)"
$MqttOpt = Read-Host "Select option [1]"
if (-not $MqttOpt) { $MqttOpt = "1" }

$UseLocalMqtt = $true
if ($MqttOpt -eq "2") {
    $UseLocalMqtt = $false
    $ExtMqttHost = Read-Host "MQTT Host"
    $ExtMqttPort = Read-Host "MQTT Port [1883]"
    if (-not $ExtMqttPort) { $ExtMqttPort = "1883" }
    $ExtMqttUser = Read-Host "MQTT Username (optional)"
    $ExtMqttPass = Read-Host "MQTT Password (optional)"
}

Write-Host "`n[4/4] WebSocket Server (Laravel Reverb):" -ForegroundColor Cyan
Write-Host "  1) Deploy local Reverb server in Docker (Default)"
Write-Host "  2) Connect to an external WebSocket server (VM / Dedicated)"
$ReverbOpt = Read-Host "Select option [1]"
if (-not $ReverbOpt) { $ReverbOpt = "1" }

$UseLocalReverb = $true
if ($ReverbOpt -eq "2") {
    $UseLocalReverb = $false
    $ExtReverbHost = Read-Host "External Reverb Host/IP"
    $ExtReverbPort = Read-Host "External Reverb Port [8085]"
    if (-not $ExtReverbPort) { $ExtReverbPort = "8085" }
}

if (-not (Test-Path ".env")) {
    Write-Host "`n[+] Creating .env from .env.example..." -ForegroundColor Green
    Copy-Item ".env.example" ".env"
}

function Set-EnvVar($Key, $Value) {
    $content = Get-Content ".env"
    if ($content -match "^$Key=") {
        $content = $content -replace "^$Key=.*", "$Key=$Value"
    } else {
        $content += "$Key=$Value"
    }
    $content | Set-Content ".env"
}

Set-EnvVar "APP_URL" "http://${ChosenHost}:8000"

if ($UseLocalDb) {
    Set-EnvVar "DB_HOST" "mariadb"
    Set-EnvVar "DB_PORT" "3306"
} else {
    Set-EnvVar "DB_HOST" $ExtDbHost
    Set-EnvVar "DB_PORT" $ExtDbPort
    Set-EnvVar "DB_DATABASE" $ExtDbName
    Set-EnvVar "DB_USERNAME" $ExtDbUser
    Set-EnvVar "DB_PASSWORD" $ExtDbPass
}

if ($UseLocalMqtt) {
    Set-EnvVar "LARAIOT_MQTT_HOST" "mqtt-broker"
    Set-EnvVar "LARAIOT_MQTT_PORT" "1883"
} else {
    Set-EnvVar "LARAIOT_MQTT_HOST" $ExtMqttHost
    Set-EnvVar "LARAIOT_MQTT_PORT" $ExtMqttPort
    if ($ExtMqttUser) {
        Set-EnvVar "LARAIOT_MQTT_AUTH_TYPE" "credentials"
        Set-EnvVar "LARAIOT_MQTT_USERNAME" $ExtMqttUser
        Set-EnvVar "LARAIOT_MQTT_PASSWORD" $ExtMqttPass
    } else {
        Set-EnvVar "LARAIOT_MQTT_AUTH_TYPE" "none"
    }
}

if ($UseLocalReverb) {
    Set-EnvVar "REVERB_HOST" "reverb"
    Set-EnvVar "REVERB_SERVER_HOST" "reverb"
    Set-EnvVar "REVERB_PORT" "8080"
    Set-EnvVar "VITE_REVERB_HOST" "`"$ChosenHost`""
    Set-EnvVar "VITE_REVERB_PORT" "8085"
} else {
    Set-EnvVar "REVERB_HOST" $ExtReverbHost
    Set-EnvVar "REVERB_SERVER_HOST" $ExtReverbHost
    Set-EnvVar "REVERB_PORT" $ExtReverbPort
    Set-EnvVar "VITE_REVERB_HOST" "`"$ExtReverbHost`""
    Set-EnvVar "VITE_REVERB_PORT" $ExtReverbPort
}

$CoreServices = @("app", "webserver")
if ($UseLocalDb) { $CoreServices = @("mariadb") + $CoreServices }
if ($UseLocalMqtt) { $CoreServices = @("mqtt-broker") + $CoreServices }

Write-Host "`n[+] Starting selected core containers ($CoreServices)..." -ForegroundColor Green
docker compose up -d --build $CoreServices

Write-Host "`n[+] Installing Composer dependencies..." -ForegroundColor Green
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader

Write-Host "`n[+] Generating application key..." -ForegroundColor Green
docker compose exec app php artisan key:generate --force

if ($UseLocalDb) {
    Write-Host "`n[+] Waiting for local MariaDB to initialize..." -ForegroundColor Green
    Start-Sleep -Seconds 10
}

Write-Host "`n[+] Running LaraIoT installation..." -ForegroundColor Green
docker compose exec app php artisan laraiot:install --ui --force

Write-Host "`n[+] Running database migrations..." -ForegroundColor Green
docker compose exec app php artisan migrate --force

Write-Host "`n[+] Installing and building frontend assets..." -ForegroundColor Green
docker compose exec app npm install
docker compose exec app npm run build

$WorkerServices = @("mqtt-listener")
if ($UseLocalReverb) { $WorkerServices = @("reverb") + $WorkerServices }

Write-Host "`n[+] Starting worker containers ($WorkerServices)..." -ForegroundColor Green
docker compose up -d $WorkerServices

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " LaraIoT is ready to use!" -ForegroundColor Green
Write-Host " Local Web UI:         http://localhost:8000/laraiot" -ForegroundColor White
Write-Host " LAN Web UI:           http://${ChosenHost}:8000/laraiot" -ForegroundColor White
if ($UseLocalMqtt) {
    Write-Host " MQTT Broker for IoT:  mqtt://${ChosenHost}:1883" -ForegroundColor White
} else {
    Write-Host " MQTT Broker for IoT:  mqtt://${ExtMqttHost}:${ExtMqttPort}" -ForegroundColor White
}
if ($UseLocalReverb) {
    Write-Host " WebSocket Server:     ws://${ChosenHost}:8085" -ForegroundColor White
}
Write-Host "`n[i] Network Checklist:" -ForegroundColor Cyan
Write-Host "    1. If using DHCP, reserve IP $ChosenHost for MAC $DetectedMac in your router." -ForegroundColor Yellow
Write-Host "    2. Ensure Windows Defender Firewall allows ports: 8000 (HTTP), 1883 (MQTT), 8085 (WS)." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan