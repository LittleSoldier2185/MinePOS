# MinePOS — Progress & Next Steps

## Done so far (Flutter app in `pos/`)
- **Welcome screen** — centered-card design, "Connect to Server" / "Create Shop" entry points, custom Windows title bar (`core/window/custom_title_bar.dart`), responsive across Windows/Android/Web.
- **Create Shop wizard** (screens 2–6) — shop details (with a real image-picker logo), admin account, connection mode (local disabled off-Windows), printer setup (UI shell only, no real Bluetooth/USB scanning yet), summary/finish.
- **Connect to Server** (screen 22) — mDNS discovery tab (via `bonsoir`, real code but nothing broadcasts yet so it'll find nothing until a host exists) + manual address tab, with a mixed-content warning on Web.
- **Login** (screen 7) — username/password, show/hide toggle, Forgot Password link (stub screen).

## Stubbed and will need real implementations later
- `ConnectionService.testConnection` (`lib/features/connect/services/connection_service.dart`) — simulates success/failure; needs a real HTTP health-check once a host exists.
- `AuthService.login` (`lib/features/auth/services/auth_service.dart`) — always succeeds once fields are filled; needs real credential checking (bcrypt + JWT) against a server.
- `HomePlaceholderScreen` — stands in for the real role-based dashboard.
- Printer setup step — records a Bluetooth/USB/Skip preference only, no actual device discovery.

## Not started yet
- **Backend**: no Dart Shelf HTTP/WebSocket host server exists at all. Needed for: real auth, real connection checks, mDNS *broadcasting* (the client-side discovery code already expects service type `_minepos._tcp`), offline order buffering/sync, KDS websocket updates.
- **Forgot Password flow** (screens 8–10): username entry → OTP verification → reset password. Currently just a "Coming soon" stub.
- **Role selection screen** (21).
- **Cashier screens** (11–14): order taking, order history, payment (cash/PromptPay QR), receipt preview/print.
- **Kitchen Display System** (15).
- **Manager screens** (16–19): reports/CSV export, menu management, staff management, settings.
- **Customer-facing display** (20).
- Thermal receipt printing (Bluetooth/USB) — real integration.

## Open question (from the original spec)
Web builds connecting to a local `http://` host from an `https://`-served page may be blocked as mixed content. Surfaced as a UI note on the Connect screen for now; a real fix needs the host server to serve TLS.

## Suggested order
1. Forgot Password / OTP / Reset flow — completes the Auth section and is UI-only, same pattern as everything built so far.
2. Start the Dart Shelf backend — even a minimal server (health endpoint + mDNS broadcast) lets `ConnectionService` and `AuthService` become real instead of stubbed.
3. Cashier flow (order taking → payment → receipt) — the core POS loop and the next big chunk of screens.
