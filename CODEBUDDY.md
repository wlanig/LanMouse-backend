# CODEBUDDY.md

This file provides guidance to CodeBuddy Code when working with code in this repository.

## Project Overview

LanMouse is a phone-as-touchpad system that lets users control a PC mouse via their mobile phone over a local network. It has three main components: a Spring Boot backend, a Flutter mobile app, and an Electron PC server.

## Architecture

```
Mobile App (Flutter)  <---TCP:19876--->  PC Server (Electron)
       |                                        |
       +----------HTTP/REST----------+----------+
                                    Backend (Spring Boot)
                                    MySQL + Redis
```

- **Mobile <-> Backend**: HTTP/REST for auth, device management, subscriptions, payments (all under `/api/*`)
- **Mobile <-> PC Server**: Raw TCP socket on port 19876, JSON messages for mouse control (move, click, scroll, drag), auth handshake, heartbeat
- **Mobile -> PC Server**: UDP broadcast on port 19877 for LAN service discovery
- **PC Server -> Backend**: `GET /api/verify/subscription` to validate device subscriptions

## Component Details

### Backend (`backend/`)
- Java 17, Spring Boot 2.7.18, MyBatis-Plus 3.5.3.1, MySQL 8.0, Redis, JWT (jjwt 0.11.5)
- Package: `com.lanmouse`
- Layers: Controller -> Service -> ServiceImpl -> Mapper (MyBatis-Plus BaseMapper) -> Entity
- JWT: 24h access token, 7-day refresh. `JwtInterceptor` on `/api/**` (excludes login/register/health/verify)
- API response envelope: `{"code": 0, "msg": "success", "data": {...}}`
- Error codes: 0=success, 1xxx=param errors, 2xxx=auth errors, 3xxx=device errors, 4xxx=order errors, 5xxx=permission errors
- Config: `src/main/resources/application.yml` (server port 8080, MySQL, Redis, JWT secret, WeChat mini-program credentials)

### Mobile (`mobile/`)
- Flutter 3.x (SDK >=3.0.0 <4.0.0), Dart, Provider state management
- Structure: `lib/config/` (app config, theme), `lib/models/`, `lib/services/` (API, Socket, UDP discovery, storage), `lib/providers/` (state), `lib/pages/`, `lib/widgets/`, `lib/utils/`
- API base URL configured in `lib/config/app_config.dart` (`api.lanmouse.com:8080`)
- TCP port 19876, UDP discovery port 19877

### PC Server (`pc-server/`)
- Electron 28.0.0 + Node.js 18+, Python 3.7+ for mouse control
- `main.js`: Electron main process (window, tray, IPC, spawns Python mouse controller)
- `tcp_server.js`: TCP socket server (connections, JSON message parsing, dispatch to mouse controller)
- `mouse_controller.py`: Reads JSON commands from stdin, executes mouse operations via platform APIs:
  - Windows: ctypes/user32.dll (primary), pyautogui (fallback)
  - macOS: CoreGraphics via ctypes, pyautogui (fallback)
  - Linux: pyautogui with xdotool fallback
- `preload.js`: Context bridge for secure renderer<->main IPC
- Config stored via electron-store at `%APPDATA%/lanmouse-pc-server/config.json`

### Deploy Package (`deploy_package/`)
- Self-contained copy of backend with `deploy.sh` for one-command deployment to CentOS/Rocky Linux
- Uses JPA instead of MyBatis-Plus; includes extra config classes (SecurityConfig, RedisConfig, CorsConfig)
- Production `application.yml` uses `lanmouse` DB user (not root)

## Build & Run Commands

### Backend
```bash
cd backend
# Initialize database (first time only)
mysql -u root -p < sql/init.sql
# Run in dev mode
./mvnw spring-boot:run
# Build JAR
mvn clean package -DskipTests
# Run production JAR
java -jar target/lanmouse-backend-1.0.0.jar
# Run tests
mvn test
```
Prerequisites: JDK 17+, MySQL 8.0+, Redis 6.0+

### Mobile
```bash
cd mobile
flutter pub get
flutter run              # debug
flutter run --release    # release
flutter build apk --release
flutter build ios --release
flutter test
flutter analyze          # lint
```
Prerequisites: Flutter SDK >=3.0.0, Android Studio / Xcode

### PC Server
```bash
cd pc-server
npm install
npm start          # production
npm run dev        # dev with logging
npm run build      # package distributable (electron-builder)
npm run pack       # package to directory
```
Prerequisites: Node.js 18+, Python 3.7+

## Database

- Database: `lanmouse` (MySQL 8.0)
- Tables: `users`, `user_groups`, `devices`, `subscriptions`, `payment_qr_codes`
- Naming: snake_case tables/columns, `idx_{table}_{column}` indexes, BIGINT auto-increment PKs, `created_at`/`updated_at` timestamps
- Init script: `backend/sql/init.sql` (also `deploy_package/sql/init.sql`)
- Migration: `backend/sql/add_openid.sql` (adds WeChat openid column)
- Test account: phone `13800138000`, password `123456`

## Coding Conventions

- **Java**: Google Java Style Guide, Lombok, camelCase
- **Dart/Flutter**: Dart Style Guide, flutter_lints, PascalCase for widgets
- **JavaScript**: Airbnb Style Guide, ES6+
- **Git commits**: Conventional commits (`feat:`, `fix:`, `docs:`, `style:`, `refactor:`, `test:`, `chore:`)
- **Branches**: `main`, `develop`, `feature/*`, `fix/*`
- **API design**: RESTful, JSON with `{code, msg, data}` envelope

## Key Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8080 | HTTP | Backend REST API |
| 19876 | TCP | PC server mouse control socket |
| 19877 | UDP | LAN service discovery broadcast |
