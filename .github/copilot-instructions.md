# GitHub Copilot Instructions

This file provides project-specific guidance to GitHub Copilot when working in this repository.

## Project Overview

Multi-project monorepo containing:
- `openim_flutter_app/` — Flutter IM client (iOS/Android/Web/Windows)
- `openim-admin-web/` — React admin dashboard (UMI + Ant Design Pro)
- `openim-chat/` — Go backend services (chat-api :10008, admin-api :10009)
- `open-im-server-main/` — Go IM core server (ws :10001, api :10002)
- `openim-docker/` — Docker Compose orchestration

---

## ⚠️ CRITICAL: Docker Rebuild Required After Go Changes

All backend services run in **Docker containers** (not natively). The `openim-chat` container uses a **locally built image** (`openim-chat-local:latest`) compiled from `openim-chat/` source.

**After ANY change to Go source files in `openim-chat/`, you MUST rebuild and restart the container:**

```bash
# From d:\procket\IMCHAT\openim-docker\
docker build -t openim-chat-local:latest ../openim-chat
docker compose -f docker-compose.yaml -f docker-compose.override.yml up -d openim-chat
```

One-liner:
```bash
docker stop openim-chat ; docker rm openim-chat ; docker build -t openim-chat-local:latest ../openim-chat ; docker compose -f docker-compose.yaml -f docker-compose.override.yml up -d openim-chat
```

Wait for healthy:
```bash
docker ps --filter name=openim-chat
# Expected: Up N seconds (healthy)
```

**Failure to rebuild = source changes have zero effect on the running service.**

---

## Backend Services

| Service | Container | Ports | Image |
|---------|-----------|-------|-------|
| IM WebSocket + API | openim-server | 10001, 10002 | openim/openim-server:v3.8.x (prebuilt) |
| Chat API + Admin API | openim-chat | 10008, 10009 | openim-chat-local:latest (**rebuilt from source**) |
| MongoDB | mongo | 37017 | mongo:7.0 |
| Redis | redis | 16379 | redis:7.0 |

`openim-server` uses a prebuilt image — do NOT attempt to modify it directly.

---

## Admin Web (`openim-admin-web/`)

- **Dev server port:** `8001` (UMI, started with `npm run dev`)
- **Tech stack:** UMI 4 + React + Ant Design Pro + TypeScript
- **API proxy:** path-prefixed proxy in `config/proxy.ts`
  - `/admin_api/` → `http://localhost:10009`
  - `/im_api/` → `http://localhost:10002`
  - `/chat_api/` → `http://localhost:10008`
- **Token storage:** localStorage keys `openim_admin_token` + `openim_im_token` (see `src/services/openim/request.ts`)
- **Default login:** account `imAdmin`, password `openIM123`

### Admin API conventions

- All admin requests use `adminRequest()` → hits 10009 via `/admin_api/` prefix
- All IM requests use `imRequest()` → hits 10002 via `/im_api/` prefix
- The login response (`AdminLoginResp`) returns both `adminToken` and `imToken`
- Every request must include `operationID` header (set to `String(Date.now())` in request.ts)

---

## Go Backend (`openim-chat/`)

### API Layer Structure

```
internal/api/admin/
  admin.go    — HTTP handler functions
  start.go    — Route registration (Gin router)
```

### Adding a new admin API endpoint

1. Add handler function to `admin.go`
2. Register route in `start.go` under the appropriate router group
3. Rebuild Docker image (see critical section above)

### Route groups in start.go

| Router var | Path prefix | Auth |
|------------|-------------|------|
| `adminRouterGroup` | `/account` | public |
| `userRouter` | `/user` | `mw.CheckAdmin` |
| `groupRouter` | `/group` | `mw.CheckAdmin` |
| `messageRouter` | `/msg` | `mw.CheckAdmin` |
| `statistic` | `/statistic` | `mw.CheckAdmin` |

### Password hashing convention

- Admin passwords: **MD5** (sent from frontend, stored as MD5 hex)
- User passwords: **SHA-256** (applied in `registerChatUser` and `ResetUserPassword`)
- When calling `adminLogin` from frontend: `password: md5(plaintext)`

### Proto field names (common gotchas)

- `GetJoinedGroupListReq` → field is `fromUserID` (not `userID`)
- `GetGroupsReq` → search fields are `groupName` + `groupID` (NOT `keyword`)
- `SearchMessageReq` → uses `sendID`, `recvID`, `contentType`, `sendTime`, `sessionType` (no `keyword` or `groupID`)

---

## Flutter App (`openim_flutter_app/`)

- **Supported platforms:** Android, iOS, Web, Windows
- **API host:** compile-time via `--dart-define=API_HOST=<ip>` (default `192.168.0.136`)
- **State management:** `ChangeNotifier` providers — `AuthController`, `ConversationController`, `ChatController`
- **Platform layouts:** `desktop_layout.dart`, `mobile_layout.dart`, `web_layout.dart`
- **User roles:** `appRole` 0 = regular user, 1 = admin

Run commands:
```bash
flutter run -d windows
flutter run -d chrome --dart-define=API_HOST=192.168.1.100
flutter analyze
flutter test
```

---

## Common Pitfalls

1. **404 on any `/admin_api/` or `/chat_api/` endpoint** → likely Go source was changed but Docker image was not rebuilt. Rebuild `openim-chat-local:latest`.
2. **Login returns `PasswordError`** → frontend must send MD5 of password; default password is `openIM123` → MD5 = `fb01f147b53025cb74aae37eb0a4f46e`.
3. **Missing `operationID` header** → backend returns `errCode: 1001 ArgsError`. Always include `operationID` in every request.
4. **imToken missing after login** → `AdminLoginResp` includes `imToken` field; ensure `setTokens(resp.data.adminToken, resp.data.imToken)` is called on login success.
5. **Group search returns empty** → `GetGroupsReq` uses `groupName`/`groupID` not `keyword`. Pass them separately.
