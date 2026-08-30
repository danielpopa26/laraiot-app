<p align="center">
  <img src="docs/assets/laraiot-logo.png" alt="LaraIoT logo" width="180">
</p>

<h1 align="center">LaraIoT App</h1>

<p align="center">Demonstration Laravel application for monitoring and controlling IoT equipment.</p>

## 1. Overview

`laraiot-app` is the reference application for the [`danpopa/laraiot`](https://packagist.org/packages/danpopa/laraiot) package. It provides a reproducible Docker environment for demonstrating the integration of Laravel, MQTT, a relational database, and real-time communication through Polling and WebSockets.

The application is intended for research, education, prototyping, and controlled demonstrations. It is not a professional, production-ready IoT platform.

## 2. Project objectives

1. Demonstrate the use of Laravel for IoT web applications.
2. Integrate MQTT communication for telemetry and commands.
3. Compare Polling and WebSocket state updates.
4. Provide a reproducible environment for tests and experiments.
5. Support evaluations of latency, network traffic, and resource consumption.

## 3. Docker Compose architecture

| Service | Image / environment | Internal port | Host port | Role |
|---|---|---:|---:|---|
| `app` | PHP 8.3-FPM (Alpine) | `9000` | â€” | Runs Laravel, LaraIoT and APIs |
| `webserver` | Nginx (Alpine) | `80` | `8000` | HTTP reverse proxy and static assets |
| `mariadb` | MariaDB 11.2 | `3306` | `3307` | Persists devices, topics and logs |
| `mqtt-broker` | Eclipse Mosquitto | `1883` | `1883` | MQTT broker |
| `reverb` | PHP CLI / Laravel Reverb | `8080` | `8085` | WebSocket broadcasting |
| `mqtt-listener` | PHP CLI | â€” | â€” | Processes MQTT messages |

The services communicate through the internal Docker Compose network. Host ports can be changed in the Compose files and `.env`.

## 4. Requirements

- Docker Engine and Docker Compose v2;
- Git;
- access to the ports used by the application;
- Linux, macOS, Windows, or WSL2 for the supplied scripts.

The Docker images provide PHP, Node.js, MariaDB, Mosquitto, and Reverb. Their versions should be treated as the reference environment for reproducing experiments.

## 5. Automated installation

```bash
git clone https://github.com/danielpopa26/laraiot-app.git
cd laraiot-app
chmod +x setup.sh
./setup.sh
```

Available scripts are `setup.sh` for Linux/macOS/WSL2, `setup.ps1` for PowerShell, and `setup.cmd` / `setup.bat` for Command Prompt. Depending on the selected configuration, the scripts prepare `.env`, build and start containers, install dependencies, generate `APP_KEY`, install LaraIoT, run migrations, build the frontend, and start Reverb and the MQTT listener.

## 6. Manual installation

```bash
cp .env.example .env
docker compose up -d --build mariadb app webserver mqtt-broker
docker compose exec -u root app sh -c "mkdir -p storage/framework/{sessions,views,cache} storage/logs bootstrap/cache && chmod -R 777 storage bootstrap/cache"
docker compose exec app composer install --no-interaction --prefer-dist --optimize-autoloader
docker compose exec app php artisan key:generate --ansi
docker compose exec app php artisan laraiot:install --ui --force
docker compose exec app php artisan migrate --force
docker compose exec app npm install
docker compose exec app npm run build
docker compose up -d reverb mqtt-listener
```

## 7. Accessing and testing the application

The interface is available at:

```text
http://localhost:8000/laraiot
```

To simulate a device publishing JSON telemetry:

```bash
docker compose exec mqtt-broker mosquitto_pub \
  -t "devices/sensor-01/telemetry" \
  -m '{"temperature":24.5,"humidity":62.0,"status":"active"}'
```

The message is received by `mqtt-listener`, processed by LaraIoT and persisted when the topic is configured and validated. In WebSocket mode, the interface can receive the update without reloading the page.

## 8. Polling and WebSockets

- **Polling** periodically requests state data from the server.
- **WebSockets** sends state events to connected clients through Laravel Reverb.

The application is designed to compare these approaches under controlled conditions. The demonstration WebSocket channel is public and must not be exposed in production without authentication, authorization, and additional security controls.

## 9. Reproducibility

For reproducible experiments, record the commit or tag, Docker image versions, host hardware, number of devices and topics, Polling interval, service status, measured values, and collection method. Keep experimental changes separate from the stable demonstration version.

## 10. Security and intended use

This application is intended for research, education, prototyping, and controlled demonstrations. Before production use, developers must implement and verify authentication, authorization, protected WebSocket channels, TLS, MQTT broker security, secret management, rate limiting, logging, and monitoring.

## 11. Troubleshooting

```bash
docker compose ps
docker compose logs --tail=100 app
docker compose logs --tail=100 mqtt-listener
docker compose logs --tail=100 reverb
docker compose exec app php artisan route:list
docker compose exec app php artisan migrate:status
```

## 12. Relation to the LaraIoT package

The reusable package is available in the [`laraiot`](https://github.com/danielpopa26/laraiot) repository. This application is a demonstration consumer of a published package version.

## 13. Authors

- **Daniel POPA**, PhD student, Department of Electronics and Telecommunications, Faculty of Electrical Engineering and Information Technology, University of Oradea, Oradea, Romania.
- **Ioan BUCIU**, Professor, PhD, Habilitated Doctor, Department of Electronics and Telecommunications, Faculty of Electrical Engineering and Information Technology, University of Oradea, Oradea, Romania.

## 14. Citation and license

For citation, consult `CITATION.cff` in the package repository. The application is distributed under the [MIT license](LICENSE).
