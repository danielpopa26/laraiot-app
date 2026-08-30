<p align="center">
    <img src="docs/assets/laraiot-logo.png" alt="Logo LaraIoT" width="180">
</p>

<h1 align="center">LaraIoT App (Aplicația Model Demonstrativă)</h1>

<p align="center">
    O aplicatie Laravel demonstrativa și extensibila pentru monitorizarea și controlul echipamentelor IoT.
</p>

## Prezentare generală

LaraIoT-App este aplicația model (template/reference application) creată special pentru a oferi un mediu gata de utilizare (out-of-the-box) celor care doresc să testeze capabilitățile pachetului danpopa/laraiot. 

Proiectul integrează întregul ecosistem necesar funcționării unei soluții IoT moderne:Broker MQTT (Eclipse Mosquitto) pentru recepția și transmiterea asincronă a pachetelor de telemetrie de la senzori/echipamente. Bază de date relațională (MariaDB) pentru persistența echipamentelor, topicurilor și istoricului stărilor.  Server WebSocket (Laravel Reverb) pentru propagarea evenimentelor în timp real către browser.  Proces de fundal (MQTT Listener Daemon) dedicat ingestiei continui a fluxurilor MQTT.  Interfață Single-Page Application (SPA) bazată pe Vue.js 3, Inertia.js și Tailwind CSS.  Aplicația este 100% containerizată prin Docker Compose, eliminând dependențele de sistemul de operare gazdă și garantând reproductibilitatea experimentală necesară în cercetarea academică.  

## Scopul și contextul academic

ServiciuImagine / MediuPort InternPort Gazdă (Host)Rol în EcosistemappPHP 8.3-FPM (Alpine)  app:9000-Execuția Laravel, logica pachetului LaraIoT, API-uri  webserverNginx Alpinewebserver:80  8000  Gateway HTTP, servire fișiere statice frontend  mariadbMariaDB 11.2  mariadb:3306  3307  Stocarea echipamentelor fizice/logice și log-urilor  mqtt-brokerEclipse Mosquitto  mqtt-broker:1883  1883  Brokerul MQTT de mesaje pentru echipamentele fizice  reverbPHP CLI (Laravel Reverb)  reverb:8080  8085  Transmisie WebSocket de mare viteză către interfață  mqtt-listenerPHP CLI (laraiot:mqtt-listen)  --Demon de fundal pentru ascultarea topicurilor MQTT  

## Arhitectura containerizată Docker

Toate serviciile necesare sunt izolate în containere dedicate:

<p align="center">
    <img src="docs/assets/table-docker-arhitecture.png" alt="Logo LaraIoT" width="180">
</p>

## Metode de instalare și configurare

Aplicația suportă două moduri de punere în funcțiune: automatizată (recomandată) și manuală pas cu pas.

**Varianta A**: Instalare automatizată prin Scripturi dedicate (Cross-Platform)

Pentru a asigura o instalare fără bătăi de cap indiferent de platformă, proiectul include 3 scripturi de inițializare:

- setup.sh – pentru medii Linux / macOS / WSL2 (Bash)  
- setup.ps1 – pentru medii Windows (PowerShell)
- setup.cmd / setup.bat – pentru terminalul clasic Windows Command Prompt.

Pași de instalare (exemplu Linux/Bash):

```bash
git clone https://github.com/danielpopa26/laraiot-app.git
cd laraiot-app
chmod +x setup.sh
./setup.sh
```

Ce execută automat scriptul:

1. Diagnosticarea interfeței de rețea (detectare IP LAN, Hostname, MAC) pentru configurarea statică a adreselor IoT.  
2. Configurarea interactivă și sincronizarea automată a variabilelor în .env (Mod local Docker sau conectare la servere externe de DB/MQTT/Reverb).  
3. Configurarea permisiunilor locale și crearea directoarelor storage și bootstrap/cache.  
4. Pornirea containerelor de bază, instalarea dependențelor prin composer install și generarea APP_KEY.  
5. Inițializarea resurselor pachetului prin php artisan laraiot:install --ui --force și rularea migrărilor bazei de date.  
6. Compilarea frontend-ului (Vite / Vue 3) prin npm install și npm run build.  
7. Pornirea demonilor auxiliari (reverb și mqtt-listener).

**Varianta B**: Instalare și configurare manuală (Fără Script)

Dacă dorești control complet asupra procesului de configurare:

1. Copierea fișierului de mediu:

```bash
cp .env.example .env
```

2. Pornirea serviciilor de bază:

```bash
docker compose up -d --build mariadb app webserver mqtt-broker
```

3. Instalarea dependențelor PHP și generarea cheii:

```bash
docker compose exec app composer install
docker compose exec app php artisan key:generate
```

4. Instalarea resurselor LaraIoT și rularea migrărilor:

```bash
docker compose exec app php artisan laraiot:install --ui --force
docker compose exec app php artisan migrate
```

5. Compilarea interfeței grafice:

```bash
docker compose exec app npm install
docker compose exec app npm run build
```

6. Pornirea serviciilor de fundal:

```bash
docker compose up -d reverb mqtt-listener
```


## Autori & Afilieri Academice

- **Daniel POPA** – Student Doctorand, Departamentul de Electronică și Telecomunicații, Facultatea de Inginerie Electrică și Tehnologia Informației, Universitatea din Oradea, România.  

- Prof. univ. dr. ing. habil. **Ioan BUCIU** – Conducător de doctorat, Departamentul de Electronică și Telecomunicații, Facultatea de Inginerie Electrică și Tehnologia Informației, Universitatea din Oradea, România.  

## Citare & Identificator Academic

Pentru citarea LaraIoT, utilizați metadatele din fișierul [`CITATION.cff`](CITATION.cff). DOI-ul va fi adăugat după arhivarea primei versiuni în Zenodo.

## Licență

LaraIoT este distribuit sub licența [MIT](LICENSE).