# SyncUp Linux Server Deployment

This runbook documents the current production-style setup used in this project:

- Flutter web static files served by Nginx on port `8088`
- SyncUp API in Docker on port `18080`
- PocketBase admin UI in Docker on port `18090`

## 1) Backend deploy (Docker)

From server:

```bash
cd ~/SyncUp/backend/pocketbase-api
cp -n .env.example .env
```

Edit `.env` with real values:

```env
PORT=8080
POCKETBASE_URL=http://127.0.0.1:8090
POCKETBASE_SUPERUSER_EMAIL=admin@syncup.com
POCKETBASE_SUPERUSER_PASSWORD=@FITSyncup2026
```

Start containers:

```bash
docker compose down
docker compose up -d --build
```

Initialize data:

```bash
docker exec syncup-api npm run bootstrap
docker exec syncup-api npm run seed
docker exec syncup-api npm run migrate-passwords
```

Verify:

```bash
curl http://127.0.0.1:18080/health
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

Expected ports:

- `syncup-api` -> `0.0.0.0:18080->8080/tcp`
- `syncup-pocketbase` -> `0.0.0.0:18090->8090/tcp`

## 2) Flutter web publish

Build web output (local machine or CI):

```bash
flutter pub get
flutter build web --release
```

This project stores deploy-ready web files in `deploy/web`.

Copy to server web root:

```bash
mkdir -p /var/www/syncup
cp -r deploy/web/* /var/www/syncup/
```

## 3) Nginx config for SyncUp web on port 8088

Create `/etc/nginx/sites-available/syncup`:

```nginx
server {
    listen 8088;
    listen [::]:8088;
    server_name _;

    root /var/www/syncup;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:18080/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Enable and reload:

```bash
ln -s /etc/nginx/sites-available/syncup /etc/nginx/sites-enabled/syncup
nginx -t && systemctl reload nginx
```

## 4) Firewall rules (UFW)

```bash
ufw allow 8088/tcp
ufw allow 18080/tcp
ufw allow 18090/tcp
ufw status
```

## 5) Access URLs

- Flutter web UI: `http://<SERVER_IP>:8088`
- API health: `http://<SERVER_IP>:18080/health`
- PocketBase admin: `http://<SERVER_IP>:18090/_/`

## 6) Default demo login credentials

Seeded credentials:

- `professor` / `Professor@123`
- `student` / `Student@123`

If login fails after deployment:

```bash
docker exec syncup-api npm run seed
```

## 7) Update flow

Backend update:

```bash
cd ~/SyncUp
git pull
cd backend/pocketbase-api
docker compose up -d --build
```

Frontend update:

```bash
# build again (local/CI), then copy new files
cp -r deploy/web/* /var/www/syncup/
nginx -t && systemctl reload nginx
```

