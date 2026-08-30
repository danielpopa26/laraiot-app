<p align="center">
  <img src="docs/assets/laraiot-logo.png" alt="Logo LaraIoT" width="180">
</p>

<h1 align="center">LaraIoT App</h1>

<p align="center">
  Aplicație Laravel demonstrativă pentru monitorizarea și controlul echipamentelor IoT.
</p>

---

## 1. Prezentare generală

`laraiot-app` este aplicația model și implementarea de referință pentru pachetul [`danpopa/laraiot`](https://packagist.org/packages/danpopa/laraiot). Proiectul oferă un mediu Docker reproductibil în care poate fi demonstrată integrarea dintre Laravel, MQTT, baza de date relațională și comunicarea în timp real prin Polling și WebSockets.

Aplicația este destinată cercetării, activităților didactice, prototipării și demonstrațiilor controlate. Ea nu reprezintă o platformă IoT profesională pregătită pentru utilizare în producție.

## 2. Obiectivele proiectului

Aplicația are următoarele obiective:

1. demonstrarea utilizării framework-ului Laravel pentru aplicații web IoT;
2. integrarea comunicării MQTT pentru recepția telemetriei și transmiterea comenzilor;
3. compararea a două mecanisme de actualizare a datelor: Polling și WebSockets;
4. furnizarea unui mediu reproductibil pentru teste și experimente;
5. susținerea evaluărilor privind latența, traficul și consumul de resurse.

## 3. Arhitectura Docker Compose

Aplicația este alcătuită din următoarele servicii:

| Serviciu | Imagine / mediu | Port intern | Port gazdă | Rol |
|---|---|---:|---:|---|
| `app` | PHP 8.3-FPM (Alpine) | `9000` | — | Execută Laravel, pachetul LaraIoT și API-urile |
| `webserver` | Nginx (Alpine) | `80` | `8000` | Reverse proxy HTTP și servirea resurselor |
| `mariadb` | MariaDB 11.2 | `3306` | `3307` | Persistă dispozitivele, topicurile și jurnalele |
| `mqtt-broker` | Eclipse Mosquitto | `1883` | `1883` | Broker MQTT pentru telemetrie și comenzi |
| `reverb` | PHP CLI / Laravel Reverb | `8080` | `8085` | Transmite evenimente WebSocket către interfață |
| `mqtt-listener` | PHP CLI | — | — | Ascultă și procesează mesajele MQTT |

Serviciile comunică prin rețeaua internă creată de Docker Compose. Porturile expuse pe gazdă pot fi adaptate în fișierele de configurare și în `.env`.

## 4. Cerințe

- Docker Engine și Docker Compose v2;
- Git;
- acces la porturile utilizate de aplicație;
- un broker MQTT local sau accesibil din rețea, dacă nu se utilizează serviciul inclus;
- Linux, macOS, Windows sau WSL2 pentru scripturile furnizate.

Mediul PHP, Node.js, MariaDB, Mosquitto și Reverb este creat în containere. Versiunile utilizate de imaginea Docker trebuie considerate sursa de adevăr pentru reproducerea experimentelor.

## 5. Instalare automatizată

Clonarea repository-ului:

```bash
git clone https://github.com/danielpopa26/laraiot-app.git
cd laraiot-app
```

Scripturile disponibile sunt:

- `setup.sh` pentru Linux, macOS și WSL2;
- `setup.ps1` pentru PowerShell;
- `setup.cmd` / `setup.bat` pentru Command Prompt.

Exemplu pentru Linux, macOS sau WSL2:

```bash
chmod +x setup.sh
./setup.sh
```

În funcție de configurație, scriptul poate:

- pregăti fișierul `.env`;
- crea directoarele necesare și ajusta permisiunile;
- construi și porni containerele;
- instala dependențele PHP și frontend;
- genera `APP_KEY`;
- instala resursele LaraIoT și rula migrările;
- construi resursele Vue.js/Vite;
- porni Reverb și listener-ul MQTT.

## 6. Instalare manuală

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

## 7. Accesarea aplicației

După pornirea serviciilor, interfața este disponibilă la:

```text
http://localhost:8000/laraiot
```

Dacă portul gazdă a fost modificat, utilizați portul configurat în `.env` sau în fișierul Compose.

## 8. Verificarea fluxului MQTT

Pentru simularea unui dispozitiv care publică telemetrie JSON:

```bash
docker compose exec mqtt-broker mosquitto_pub \
  -t "devices/sensor-01/telemetry" \
  -m '{"temperature":24.5,"humidity":62.0,"status":"active"}'
```

Mesajul este recepționat de `mqtt-listener`, procesat de LaraIoT și, dacă topicul este configurat și validat, persistat în baza de date. În modul WebSocket, interfața poate primi actualizarea fără reîncărcarea paginii.

## 9. Polling și WebSockets

Aplicația permite selectarea modului de actualizare a stărilor:

- **Polling** — interfața solicită periodic datele de la server;
- **WebSockets** — serverul transmite evenimentele către clienții conectați prin Laravel Reverb.

Scopul proiectului este compararea celor două abordări în condiții controlate. Pentru modul WebSocket, canalul demonstrativ este public și nu trebuie expus într-un mediu de producție fără implementarea autentificării, autorizării și a altor măsuri de securitate.

## 10. Reproducibilitate și cercetare

Pentru experimente reproductibile, se recomandă consemnarea următoarelor elemente:

- commit-ul sau tag-ul utilizat;
- versiunile imaginilor Docker;
- configurația hardware a gazdei;
- numărul de dispozitive și topicuri;
- intervalul de Polling;
- starea serviciilor Reverb și MQTT;
- valorile măsurate și metoda de colectare.

Modificările experimentale trebuie păstrate separat de versiunea demonstrativă stabilă.

## 11. Securitate și domeniu de utilizare

Această aplicație este destinată cercetării, educației, prototipării și demonstrațiilor controlate. Configurația implicită nu trebuie utilizată pentru controlul echipamentelor într-un mediu public sau neîncrezător.

Înaintea unei eventuale utilizări în producție, dezvoltatorul trebuie să implementeze și să verifice autentificarea, autorizarea, canale WebSocket protejate, TLS, securizarea brokerului MQTT, gestionarea secretelor, limitarea cererilor, jurnalizarea și monitorizarea.

## 12. Depanare de bază

Verificarea stării serviciilor:

```bash
docker compose ps
docker compose logs --tail=100 app
docker compose logs --tail=100 mqtt-listener
docker compose logs --tail=100 reverb
```

Verificarea rutelor și a migrărilor:

```bash
docker compose exec app php artisan route:list
docker compose exec app php artisan migrate:status
```

## 13. Legătura cu pachetul LaraIoT

Codul reutilizabil și documentația pachetului sunt disponibile în repository-ul [`laraiot`](https://github.com/danielpopa26/laraiot). Această aplicație este un consumator demonstrativ al unei versiuni publicate a pachetului.

## 14. Autori

- **Daniel POPA**, student doctorand, Department of Electronics and Telecommunications, Faculty of Electrical Engineering and Information Technology, University of Oradea, Oradea, Romania.
- **Ioan BUCIU**, Professor, PhD, Habilitated Doctor, Department of Electronics and Telecommunications, Faculty of Electrical Engineering and Information Technology, University of Oradea, Oradea, Romania.

## 15. Citare

Pentru citarea software-ului LaraIoT, consultați fișierul `CITATION.cff` din repository-ul pachetului. DOI-ul proiectului este disponibil prin Zenodo după arhivarea release-ului.

## 16. Licență

Aplicația este distribuită sub licența [MIT](LICENSE).