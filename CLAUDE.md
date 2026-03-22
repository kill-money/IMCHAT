# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run on a specific platform
flutter run -d windows
flutter run -d chrome
flutter run -d android

# Run with a specific backend host (required for real devices)
flutter run -d chrome --dart-define=API_HOST=192.168.1.100
flutter run -d android --dart-define=API_HOST=192.168.1.100

# Build
flutter build apk
flutter build windows
flutter build web

# Lint
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart
```

## Architecture

This is a **multi-platform Flutter IM client** targeting Mobile (iOS/Android), Web, and Desktop (Windows/macOS/Linux) from a single codebase. It connects to an OpenIM v3.8.x self-hosted backend.

### Backend Services

The API host is configured at compile time via `--dart-define=API_HOST=<ip>`. It defaults to `192.168.0.136` in `lib/core/api/api_client.dart`. Three backend services are expected:

| Service   | Port  | Purpose                     |
|-----------|-------|-----------------------------|
| im-server | 10002 | Message/conversation APIs   |
| chat-api  | 10008 | Login & registration        |
| admin-api | 10009 | Admin operations            |
| WebSocket | 10001 | Real-time messaging (ws://) |

### Platform Routing

`main.dart` detects platform at startup and sets `ApiConfig.isWeb` / `ApiConfig.isDesktop`. The `/home` route returns a different layout widget per platform:
- `ui/desktop/desktop_layout.dart` — 3-panel layout (icon sidebar + conversation list + chat), system tray integration
- `ui/mobile/mobile_layout.dart` — bottom navigation bar
- `ui/web/web_layout.dart` — responsive web layout

### State Management

Three `ChangeNotifier` providers are registered globally in `main.dart`:
- `AuthController` (`core/controllers/`) — authentication state and current user info
- `ConversationController` — conversation list
- `ChatController` — message history and sending

### API Layer

`lib/core/api/api_client.dart` holds `ApiConfig` (static token + host config) and a shared HTTP client. Auth tokens are injected per-request from `ApiConfig` static fields. `ImApi` wraps the im-server; `ChatApi` wraps the chat/login API.

### Shared UI

`lib/shared/widgets/ui/` contains the custom design system components (`AppButton`, `AppCard`, `AppBadge`, `AppHeader`, `AppModal`, etc.). Theming tokens (colors, spacing, typography) live in `lib/shared/theme/`.

### User Roles

`UserInfo.appRole` field: `0` = regular user, `1` = admin (grants IP visibility permissions in the UI).

### Desktop Notes

Desktop windows initialize via `lib/core/desktop_window.dart` (size: 1100×700, minimum: 800×600). Window close minimizes to system tray instead of quitting (uses `window_manager` + `system_tray` packages).

## Backend Infrastructure (Docker)

All backend services run inside **Docker containers** managed by `openim-docker/docker-compose.yaml` + `docker-compose.override.yml`.

| Container | Image | Ports |
|-----------|-------|-------|
| openim-server | openim/openim-server:v3.8.x | 10001, 10002 |
| openim-chat | openim-chat-local:latest | 10008, 10009 |
| mongo | mongo:7.0 | 37017 |
| redis | redis:7.0 | 16379 |

### ⚠️ CRITICAL: Rebuilding after Go source changes

The `openim-chat` service (ports 10008/10009) is built from local source at `openim-chat/`. **After any Go source code change, the Docker image MUST be rebuilt and the container restarted**, otherwise changes have no effect.

```bash
# Run from d:\procket\IMCHAT\openim-docker\
docker build -t openim-chat-local:latest ../openim-chat
docker compose -f docker-compose.yaml -f docker-compose.override.yml up -d openim-chat
```

One-liner (stop → remove → rebuild → restart):
```bash
docker stop openim-chat ; docker rm openim-chat ; docker build -t openim-chat-local:latest ../openim-chat ; docker compose -f docker-compose.yaml -f docker-compose.override.yml up -d openim-chat
```

Wait for healthy status before testing:
```bash
docker ps --filter name=openim-chat
# Expected: Up N seconds (healthy)
```

### Admin Web Dev Server

The admin web (`openim-admin-web/`) runs on **port 8001** (UMI dev server). Start with:
```bash
cd openim-admin-web
npm run dev
```

Default admin credentials: account `imAdmin`, password `openIM123`.

### Proxy Configuration

The UMI dev server proxies API calls via path prefix:
- `/admin_api/` → `http://localhost:10009`
- `/im_api/` → `http://localhost:10002`
- `/chat_api/` → `http://localhost:10008`
