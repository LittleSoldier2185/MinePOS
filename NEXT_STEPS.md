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

## Done so far — Manager screens (16, 18–19)
- **Staff Management** (screen 18) — owner-only. List/create staff (username, temp password, role), deactivate/reactivate, force sign-out on all devices, remove. Backed by new `POST/GET /users`, `PATCH /users/:username`, `POST /users/:username/logout`, `DELETE /users/:username` routes (see below).
- **Reports** (screen 16) — quick-range chips (Today/Yesterday/Last 7/30 Days/All Time/Custom via date-range picker), stats (orders, revenue, avg, cash vs PromptPay split) computed client-side from `GET /orders`, order list, CSV export (`file_picker` save dialog, UTF-8 BOM for Excel) via a dedicated `ReportsService`.
- **Settings** (screen 19) — shows signed-in username/role, "Disconnect" (clears session, returns to Welcome), printer preference (Bluetooth/USB/None) and language (English/Thai) selectors persisted locally via `shared_preferences` (`AppSettingsService`); both still UI-preference-only, no real printer discovery or i18n yet.
- Sidebar/bottom-nav now routes to all three; Staff is hidden from non-owners in the nav (also enforced server-side).
- `ServerClient` now tracks `role`/`username` post-login (`isOwner` getter) so screens can gate on role.

## Backend additions for staff management
- `users` table gained `active` and `token_version` columns (auto-migrated for existing DBs).
- New `requireAuth()` helper in `utils.dart` cross-checks the JWT against current DB state (active + token version) on every request — not just new routes — so a deactivated account or a forced logout takes effect immediately instead of waiting for the JWT to expire. `menu_routes.dart` / `order_routes.dart` were switched to use it too.
- Owner cannot deactivate or delete their own account (guarded server-side).
- Verified via curl (login/create/list/deactivate/reactivate/force-logout/self-protection) and via real widget tests driven against a live local server instance (throwaway test, not committed).

## Done so far — Kitchen Display System (screen 15)
- **Kitchen Display** — live 3-column kanban board (New / Preparing / Ready) fed by a WebSocket (`ws://<host>/ws/kitchen`, JWT passed as a query param since browsers can't set custom headers on the WS handshake). Connects on screen open, auto-reconnects with a 3s backoff on drop, shows a Live/Connecting/Reconnecting/Offline badge.
- Orders carry a kitchen `status`: pending → preparing → ready → completed. New orders start `pending`; cashiers don't see or set this — it's purely the kitchen's view. Advancing a card's status PATCHes the server, which broadcasts the change to every connected display; a card marked "Complete" drops off the board (server only returns non-completed orders in the initial snapshot).
- Cards flag as urgent (red border) once they've been waiting 5+ minutes without being marked ready.
- Wired into the sidebar (desktop) and mobile popup menu for all roles — kitchen staff are often workers, so this one isn't owner-gated like Staff Management.
- Verified two ways: a standalone Dart script exercising the raw WebSocket protocol directly against the live server (snapshot delivery + live `order_created`/`order_status` broadcasts, unambiguous pass), and a widget test driving the actual screen end-to-end (order appears live, all three status-transition taps PATCH and re-render correctly, card disappears on completion). The widget test isn't committed — its final cleanup step trips an unrelated `flutter test` harness limitation (`dart:io` WebSocket close creates a real timeout timer that the fake-clock test binding can't resolve), not an app defect.

## Backend additions for Kitchen Display
- `orders` table gained a `status` column (auto-migrated; historical rows default to `completed`, new orders always insert explicit `pending`).
- New `KitchenHub` (`server/lib/kitchen_hub.dart`) fans out `order_created`/`order_status` events to all connected sockets and sends a fresh snapshot of active (non-completed) orders to each new connection.
- New `GET /ws/kitchen?token=<jwt>` route (`kitchen_routes.dart`) and `PATCH /orders/:id/status` route; both reuse the same active/token-version DB check as `requireAuth` (refactored into a shared `verifyToken` so the query-param path and the header path share logic).

## Stubbed — needs real implementation when backend exists
- `ConnectionService.testConnection` — done, real HTTP GET /health.
- `AuthService.login` — done, real HTTP POST /auth/login with bcrypt + JWT.
- `PasswordResetService` — done, real HTTP OTP flow (OTP printed to server console; wire email/SMS later).
- `MenuService` — done, fetchFromServer() + fire-and-forget writes; local fallback if server unreachable.
- `OrderService` — done, complete() POSTs to server; loadFromServer() for history.
- `StaffService` / `ReportsService` — done, real HTTP, server-authoritative (no offline fallback — these are security-sensitive/reporting operations).
- Printer setup step — records preference only; no real Bluetooth/USB discovery.
- Language selector — records preference only; no real translation strings wired up yet.

## Not started yet
- **Backend** (`server/` — Dart Shelf): health, mDNS broadcast, bcrypt+JWT auth, menu CRUD, order storage + kitchen status, staff CRUD, kitchen WebSocket — all done. Run with `dart run bin/server.dart` from `server/`. Requires `sqlite3.dll` on Windows PATH (download from https://sqlite.org/download.html). Configure via env vars: `MINEPOS_PORT` (default 8080), `MINEPOS_ADMIN_USER`, `MINEPOS_ADMIN_PASS`, `MINEPOS_SHOP_NAME`, `MINEPOS_JWT_SECRET`, `MINEPOS_DATA_DIR`.
- **Role selection screen** (screen 21).
- **Customer-facing display** (screen 20).
- Thermal receipt printing — real Bluetooth/USB integration.
- Real i18n for the Thai language option.
- Kitchen Display doesn't yet show per-item prep state, only whole-order — fine for a small menu/single-station kitchen, would need item-level tracking for a bigger kitchen.

## Open questions
- Web builds: mixed-content HTTP→HTTPS; needs TLS on the host server.
- Offline session rules: owner = persistent, worker = 30 min idle timeout (see memory note).
- Reports currently fetches the full unfiltered `/orders` list and filters client-side — fine at coffee-shop scale, but a `/orders?from=&to=` range endpoint would be worth adding if order volume grows large.

## Suggested next order
1. ~~Forgot Password / OTP / Reset~~ ✓
2. ~~Cashier flow (screens 11–14)~~ ✓
3. ~~**Manager — Menu Management (screen 17)**~~ ✓
4. ~~**Dart Shelf backend** (minimal: health + mDNS + auth)~~ ✓
5. ~~**Manager — Staff / Reports / Settings (screens 16, 18, 19)**~~ ✓
6. ~~**Kitchen Display System (screen 15)**~~ ✓
7. Remaining screens (20, 21).
