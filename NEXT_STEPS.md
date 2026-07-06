# MinePOS — Progress & Next Steps

## Done so far (Flutter app in `pos/`)
- **Welcome screen** — centered-card design, "Connect to Server" / "Create Shop" entry points, custom Windows title bar (`core/window/custom_title_bar.dart`), responsive across Windows/Android/Web.
- **Create Shop wizard** (screens 2–6) — shop details (with a real image-picker logo), admin account, connection mode (local disabled off-Windows), printer setup (UI shell only, no real Bluetooth/USB scanning yet), summary/finish.
- **Connect to Server** (screen 22) — mDNS discovery tab (via `bonsoir`, real code but nothing broadcasts yet so it'll find nothing until a host exists) + manual address tab, with a mixed-content warning on Web.
- **Login** (screen 7) — username/password, show/hide toggle, Forgot Password link.
- **Forgot Password / OTP / Reset** (screens 8–10) — username entry → 6-digit OTP box → new password; all three screens wired together. Service is stubbed (any 6-digit code passes); needs a real HTTP+email call once backend exists.

## Done so far — Cashier flow (screens 11–14)
- **Cashier hub** (HomePlaceholderScreen) — "New Order" + "Order History" buttons, today's summary tiles, logout with confirmation.
- **Order Taking** (screen 11) — category filter chips, responsive menu grid (2–5 cols via LayoutBuilder), in-cart badge overlay per item, quantity controls (+/−/×), side-by-side cart panel on wide screens / tab layout on mobile.
- **Payment** (screen 13) — Cash (quick-fill buttons, live change calculation) + PromptPay (placeholder QR panel pending PromptPay ID config). Passes completed `Order` to receipt.
- **Receipt** (screen 14) — Full receipt card (items, total, change), Print stub, "New Order" pushes a fresh `OrderTakingScreen` keeping hub in stack.
- **Order History** (screen 12) — expandable list tiles showing per-order item breakdown, cash/PromptPay details.
- **MenuService** — singleton with 24 default items; full CRUD (add/edit/delete/toggle) via `MenuManagementScreen`.
- **OrderService** — in-memory singleton, auto-incrementing order numbers, today's stats helpers.

## Stubbed — needs real implementation when backend exists
- `ConnectionService.testConnection` — ✓ real HTTP GET /health.
- `AuthService.login` — ✓ real HTTP POST /auth/login with bcrypt + JWT.
- `PasswordResetService` — ✓ real HTTP OTP flow (OTP printed to server console; wire email/SMS later).
- `MenuService` — ✓ fetchFromServer() + fire-and-forget writes; local fallback if server unreachable.
- `OrderService` — ✓ complete() POSTs to server; loadFromServer() for history.
- Printer setup step — records preference only; no real Bluetooth/USB discovery.

## Not started yet
- **Backend** (`server/` �� Dart Shelf): ✓ done (health, mDNS broadcast, bcrypt+JWT auth, menu CRUD, order storage). Run with `dart run bin/server.dart` from `server/`. Requires `sqlite3.dll` on Windows PATH (download from https://sqlite.org/download.html). Configure via env vars: `MINEPOS_PORT` (default 8080), `MINEPOS_ADMIN_USER`, `MINEPOS_ADMIN_PASS`, `MINEPOS_SHOP_NAME`, `MINEPOS_JWT_SECRET`, `MINEPOS_DATA_DIR`.
- **Manager screens** (16, 18–19):
  - Screen 16: Reports & CSV export
  - Screen 18: Staff management (add staff, deactivate, force logout)
  - Screen 19: Settings (role, connection mode, printer, language)
- **Kitchen Display System** (screen 15) — WebSocket-driven live order board.
- **Role selection screen** (screen 21).
- **Customer-facing display** (screen 20).
- Thermal receipt printing — real Bluetooth/USB integration.

## Open questions
- Web builds: mixed-content HTTP→HTTPS; needs TLS on the host server.
- Offline session rules: owner = persistent, worker = 30 min idle timeout (see memory note).

## Suggested next order
1. ~~Forgot Password / OTP / Reset~~ ✓
2. ~~Cashier flow (screens 11–14)~~ ✓
3. ~~**Manager — Menu Management (screen 17)**~~ ✓
4. ~~**Dart Shelf backend** (minimal: health + mDNS + auth)~~ ✓
5. **Manager — Staff / Reports / Settings (screens 16, 18, 19).**
6. Kitchen Display System (screen 15).
7. Remaining screens (20, 21).
