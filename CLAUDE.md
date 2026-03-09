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
