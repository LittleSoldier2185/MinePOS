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
- **MenuService** — 24 stub items across 4 categories (Coffee, Tea, Cold, Food) with Thai Baht prices.
- **OrderService** — in-memory singleton, auto-incrementing order numbers, today's stats helpers.

## Stubbed and will need real implementations later
- `ConnectionService.testConnection` (`lib/features/connect/services/connection_service.dart`) — simulates success/failure; needs a real HTTP health-check once a host exists.
- `AuthService.login` (`lib/features/auth/services/auth_service.dart`) — always succeeds once fields are filled; needs real credential checking (bcrypt + JWT) against a server.
- `HomePlaceholderScreen` — stands in for the real role-based dashboard.
- Printer setup step — records a Bluetooth/USB/Skip preference only, no actual device discovery.

## Not started yet
- **Backend**: no Dart Shelf HTTP/WebSocket host server exists at all. Needed for: real auth, real connection checks, mDNS *broadcasting* (the client-side discovery code already expects service type `_minepos._tcp`), offline order buffering/sync, KDS websocket updates.
- **Role selection screen** (21).
- **Cashier screens** (11–14): order taking, order history, payment (cash/PromptPay QR), receipt preview/print.
- **Kitchen Display System** (15).
- **Manager screens** (16–19): reports/CSV export, menu management, staff management, settings.
- **Customer-facing display** (20).
- Thermal receipt printing (Bluetooth/USB) — real integration.

## Open question (from the original spec)
Web builds connecting to a local `http://` host from an `https://`-served page may be blocked as mixed content. Surfaced as a UI note on the Connect screen for now; a real fix needs the host server to serve TLS.

## Auth rules to implement (offline mode)
- **Shop owner** — persistent offline session (no expiry). Logs in once, stays logged in.
- **Workers / non-owner staff** — session must time out automatically (suggested: configurable, default 30 min idle). Force re-login on expiry.
- Implementation: store JWT locally; on app resume check `exp` claim. Skip expiry check if `role == owner`.

## Suggested order
1. ~~Forgot Password / OTP / Reset flow~~ — **done**.
2. Start the Dart Shelf backend — even a minimal server (health endpoint + mDNS broadcast) lets `ConnectionService` and `AuthService` become real instead of stubbed.
3. Cashier flow (order taking → payment → receipt) — the core POS loop and the next big chunk of screens.
