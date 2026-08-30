# MinePOS

Offline-first point-of-sale for small food & retail shops. A Flutter app
(cashier, kitchen display, customer display, role-based navigation) talks to a
self-hosted Dart server over HTTP + WebSocket on your own LAN. No cloud account,
no subscription.

Grab a build from [Releases](https://github.com/LittleSoldier2185/MinePOS/releases),
or see [`RELEASE_NOTES.md`](RELEASE_NOTES.md) for what's in the current one.

## Architecture

```
Flutter app  ──HTTP + WebSocket──▶  Dart Shelf server  ──▶  SQLite (data/minepos.db)
(pos/)                              (server/)
```

- One machine on the network runs the server (port 8080, binds all interfaces).
- Every register / kitchen screen / customer display connects to `http://<host-ip>:8080`.
- The Windows desktop build bundles the server and can auto-start it, so a single
  PC works as host + till.
- A browser-based Shop Manager (menu, promotions, staff, advertising, reports) is
  served from the same server.

## Repo layout

| Path | What |
|---|---|
| `pos/` | Flutter app — Windows, Android, web. Features under `pos/lib/features/` (`cashier`, `kitchen`, `customer_display`, `manager`, `auth`, `shop_setup`, …) |
| `server/` | Dart Shelf backend. Entry point `server/bin/server.dart` |
| `pos/tool/` | Release build scripts (PowerShell) |
| `Document/`, `mockups/` | Design docs and UI sketches |

## Development

Requires the Flutter SDK (Dart `^3.11`). The server reuses Flutter's bundled Dart.

**Server**

```sh
cd server
dart pub get
run_server.bat          # or: dart run bin/server.dart
```

Needs `sqlite3.dll` next to `bin/server.dart` on Windows. Full notes, env vars,
and troubleshooting: [`server/SETUP_INSTRUCTIONS.txt`](server/SETUP_INSTRUCTIONS.txt).

**App**

```sh
cd pos
flutter pub get
flutter run             # -d windows | -d <android-device> | -d chrome
```

The server starts with **zero users**. Bootstrap a shop from the app: Welcome →
Create Shop → Local mode → fill in shop + first Owner account (POSTs `/setup`
once). Or set `MINEPOS_ADMIN_USER` / `MINEPOS_ADMIN_PASS` before starting the
server for a headless bootstrap.

## Building releases

From `pos/`:

| Script | Output (in `pos/build/`) |
|---|---|
| `tool/build_windows_release.ps1` | `build/windows/x64/runner/Release/` — `MinePOS.exe` + bundled `server/MinePOS Server.exe` |
| `tool/build_release_pack.ps1` | `MinePOS-Windows.zip`, `MinePOS-Server-Windows.zip`, `MinePOS-Android.apk` |

`build_release_pack.ps1` runs the Windows build, packages a standalone headless
server, and builds the release APK.

## Server configuration

All optional, set as environment variables before launch:

| Var | Default | |
|---|---|---|
| `MINEPOS_PORT` | `8080` | TCP port |
| `MINEPOS_DATA_DIR` | `data` | DB + JWT secret location |
| `MINEPOS_SHOP_NAME` | `MinePOS` | default shop name |
| `MINEPOS_ADMIN_USER` / `MINEPOS_ADMIN_PASS` | none | auto-create an admin |
| `MINEPOS_JWT_SECRET` | random (persisted) | fixed JWT signing secret |

Health check: `curl http://127.0.0.1:8080/health`.

## Data

`server/data/` holds `minepos.db` (SQLite), `server.log`, and `server.json` (JWT
secret — keep it stable or every device is logged out). Back up via the app:
file export, live device-to-device transfer, or push to a remote server.
