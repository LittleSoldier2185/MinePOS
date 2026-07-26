/// Static HTML/CSS/JS for the browser-based "MinePOS Shop Manager" served at
/// GET /admin. Deliberately a single embedded string (no shelf_static, no
/// separate asset directory, no build step) — same reasoning as before: ship
/// the whole web UI as a zero-extra-files change alongside the exe.
///
/// This is a plain HTML/CSS/vanilla-JS SPA (hash-free, just show/hide
/// `<section>`s) hitting the exact same REST routes the Flutter app's
/// Manager screens already use (menu/users/promotions/orders/shop/ads) — no
/// new backend routes were added for this page; it's a second client for
/// APIs that already exist and are already tested. Owner-only login, same as
/// before (menu/staff/promotion management already requires owner or
/// owner+manager server-side; this page itself gates the whole dashboard on
/// `role === 'owner'` for simplicity, matching the previous admin-only page).
const String adminWebPageHtml = r'''
<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>MinePOS Shop Manager</title>
<style>
  :root {
    color-scheme: dark;
    --bg: #0a0b10;
    --bg-glow: radial-gradient(1200px 640px at 12% -10%, rgba(99,102,241,.16), transparent 55%),
               radial-gradient(900px 500px at 100% 0%, rgba(34,211,238,.07), transparent 50%);
    --sidebar-bg: #0c0d12;
    --card: #15161f; --card-2: #1b1d29; --border: #262a37; --border-soft: rgba(38,42,55,.6);
    --input: #0e0f16; --text: #f2f3f8; --muted: #7d8296; --muted-soft: #b0b4c4;
    --accent: #6366f1; --accent-2: #818cf8; --accent-cyan: #22d3ee; --accent-glow: rgba(99,102,241,.35);
    --danger: #f43f5e; --danger-soft: #fda4af; --ok: #22c55e; --ok-soft: #86efac;
    --radius: 14px; --radius-sm: 9px;
  }
  * { box-sizing: border-box; }
  ::-webkit-scrollbar { width: 10px; height: 10px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 10px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--accent); }
  body {
    margin: 0; min-height: 100vh;
    background: var(--bg-glow), var(--bg); background-attachment: fixed; color: var(--text);
    font: 14.5px/1.6 -apple-system, "Segoe UI", Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  h1 { font-size: 22px; margin: 0 0 4px; font-weight: 800; letter-spacing: -.02em; }
  h2 { font-size: 12.5px; margin: 0 0 16px; color: var(--muted-soft); text-transform: uppercase; letter-spacing: .07em; font-weight: 700; }
  h3 { font-size: 13px; margin: 18px 0 8px; color: var(--muted-soft); font-weight: 700; }
  .sub { color: var(--muted); margin: 0 0 24px; }
  .page-head { margin-bottom: 22px; }
  .card {
    background: var(--card); border: 1px solid var(--border); border-radius: var(--radius);
    padding: 22px 24px; margin-bottom: 18px; max-width: 760px;
    box-shadow: 0 12px 32px -16px rgba(0,0,0,.6);
  }
  .card-grid {
    display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 18px; max-width: 1080px;
  }
  .card-grid .card { max-width: none; margin-bottom: 0; }
  label { display: block; font-size: 12px; color: var(--muted); margin: 10px 0 4px; font-weight: 600; }
  input, select, textarea {
    width: 100%; padding: 10px 12px; border-radius: 9px; border: 1px solid var(--border);
    background: var(--input); color: var(--text); font-size: 14px; font-family: inherit;
    transition: border-color .15s, box-shadow .15s;
  }
  input:focus, select:focus, textarea:focus {
    outline: none; border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-glow);
  }
  textarea { resize: vertical; min-height: 60px; }
  input[type=checkbox] { width: auto; }
  button {
    margin-top: 14px; padding: 10px 20px; border-radius: 9px; border: none;
    background: linear-gradient(135deg, var(--accent), var(--accent-2));
    color: white; font-weight: 700; cursor: pointer; font-size: 13px;
    transition: filter .15s, transform .1s, box-shadow .15s; box-shadow: 0 6px 18px -6px var(--accent-glow);
  }
  button:hover { filter: brightness(1.08); box-shadow: 0 8px 22px -6px var(--accent-glow); }
  button:active { transform: translateY(1px); }
  button.danger { background: var(--danger); color: white; box-shadow: 0 6px 18px -6px rgba(244,63,94,.4); }
  button.secondary { background: var(--card-2); color: var(--text); border: 1px solid var(--border); box-shadow: none; }
  button.secondary:hover { border-color: var(--accent); filter: none; box-shadow: none; }
  button.small { padding: 7px 12px; font-size: 12px; margin-top: 0; }
  button:disabled { opacity: .4; cursor: default; filter: none; box-shadow: none; }
  .dot {
    display: inline-block; width: 9px; height: 9px; border-radius: 50%; margin-right: 6px;
    background: #666; box-shadow: 0 0 0 3px transparent; transition: box-shadow .2s;
  }
  .dot.live { background: var(--ok); box-shadow: 0 0 0 3px rgba(34,197,94,.2); }
  .dot.off { background: var(--danger); box-shadow: 0 0 0 3px rgba(244,63,94,.2); }
  .row { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
  .msg { font-size: 12px; margin-top: 8px; }
  .msg.err { color: var(--danger-soft); }
  .msg.ok { color: var(--ok-soft); }
  ul { list-style: none; padding: 0; margin: 0; }
  li { padding: 9px 0; border-bottom: 1px solid var(--border-soft); font-size: 13px; }
  li:last-child { border-bottom: none; }
  .role { color: var(--muted); font-size: 11px; text-transform: uppercase; }
  pre {
    background: var(--input); border: 1px solid var(--border); border-radius: 9px; padding: 12px;
    max-height: 320px; overflow: auto; font-size: 12px; white-space: pre-wrap; word-break: break-all;
  }
  .field-half { display: flex; gap: 12px; }
  .field-half > div { flex: 1; }

  /* ── App shell ─────────────────────────────────────────────────────── */
  #app { display: none; min-height: 100vh; }
  .shell { display: flex; min-height: 100vh; }
  .topbar { display: none; }
  .sidebar-backdrop { display: none; }
  .sidebar {
    width: 232px; flex: none; background: var(--sidebar-bg); border-right: 1px solid var(--border);
    padding: 18px 12px; display: flex; flex-direction: column;
  }
  .sidebar .brand { padding: 4px 8px 6px; display: flex; align-items: center; gap: 10px; }
  .sidebar .brand-name { font-weight: 800; font-size: 15px; letter-spacing: -.01em; line-height: 1.2; }
  .sidebar .brand-sub { font-size: 10px; color: var(--muted); letter-spacing: .04em; text-transform: uppercase; }
  .sidebar-divider { height: 1px; background: var(--border); margin: 12px 4px 14px; flex: none; }
  .nav-group { display: flex; flex-direction: column; gap: 2px; }
  .navbtn {
    display: flex; align-items: center; width: 100%; text-align: left; background: none; border: none;
    color: var(--muted-soft); padding: 11px 12px; font-size: 13px; font-weight: 600;
    cursor: pointer; border-radius: var(--radius-sm); transition: background .15s, color .15s;
  }
  .navbtn:hover { background: #ffffff0a; color: var(--text); }
  .navbtn.active {
    background: linear-gradient(90deg, var(--accent-glow), transparent 85%);
    color: var(--text); box-shadow: inset 0 0 0 1px #ffffff14;
  }
  .navbtn .sub-nav-icon { margin-right: 10px; font-size: 14px; }
  .sidebar-footer { margin-top: auto; padding-top: 14px; }
  main { flex: 1; padding: 32px 36px; overflow-y: auto; min-width: 0; }
  section { display: none; animation: fadein .18s ease; }
  section.active { display: block; }
  @keyframes fadein { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; transform: none; } }

  /* ── Tables / lists ────────────────────────────────────────────────── */
  .table-wrap {
    overflow-x: auto; border: 1px solid var(--border); border-radius: var(--radius-sm);
    margin-top: 14px; background: var(--input);
  }
  table { width: 100%; border-collapse: collapse; font-size: 13px; min-width: 480px; }
  th { text-align: left; color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: .04em;
       padding: 11px 14px; border-bottom: 1px solid var(--border); white-space: nowrap; }
  td { padding: 11px 14px; border-bottom: 1px solid var(--border-soft); vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tbody tr:nth-child(even) { background: #ffffff03; }
  tbody tr:hover { background: var(--accent-glow); background: rgba(99,102,241,.07); }
  .chip {
    display: inline-flex; align-items: center; padding: 6px 14px; border-radius: 20px;
    border: 1px solid var(--border); background: var(--card-2); color: var(--muted-soft); font-size: 12px; font-weight: 600;
    cursor: pointer; margin: 0 6px 6px 0; user-select: none; transition: all .12s;
  }
  .chip:hover { border-color: var(--accent); color: var(--text); }
  .chip.sel { background: var(--accent); border-color: var(--accent); color: white; }
  .chip.dim { opacity: .5; }
  .badge {
    display: inline-block; padding: 4px 10px; border-radius: 6px; font-size: 10px;
    font-weight: 700; letter-spacing: .03em; text-transform: uppercase; background: var(--card-2); color: var(--muted-soft);
  }
  .stat-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 12px; margin-bottom: 18px; }
  .stat-card {
    background: var(--card); border: 1px solid var(--border); border-left: 3px solid var(--accent);
    border-radius: var(--radius-sm); padding: 14px 16px;
    box-shadow: 0 10px 26px -16px rgba(0,0,0,.6);
  }
  .stat-card .v { font-size: 21px; font-weight: 800; }
  .stat-card .l { font-size: 10px; color: var(--muted); letter-spacing: .04em; margin-top: 4px; text-transform: uppercase; font-weight: 600; }
  .toggle-track {
    display: inline-block; width: 34px; height: 18px; border-radius: 10px; background: var(--border);
    position: relative; cursor: pointer; vertical-align: middle; transition: background .15s;
  }
  .toggle-track.on { background: var(--accent); }
  .toggle-track .knob {
    position: absolute; top: 2px; left: 2px; width: 14px; height: 14px; border-radius: 50%;
    background: white; transition: left .15s;
  }
  .toggle-track.on .knob { left: 18px; }
  .item-checklist {
    max-height: 220px; overflow-y: auto; border: 1px solid var(--border); border-radius: 9px; padding: 8px 12px;
    background: var(--input);
  }
  .item-checklist label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--text); margin: 7px 0; font-weight: 400; }
  .item-checklist input { width: auto; }
  .thumb { width: 44px; height: 44px; border-radius: 9px; object-fit: cover; background: var(--input); }
  .thumb-clickable { cursor: pointer; transition: transform .12s, box-shadow .12s; }
  .thumb-clickable:hover { transform: scale(1.06); box-shadow: 0 0 0 2px var(--accent); }
  .hidden { display: none !important; }

  /* ── Media preview lightbox ───────────────────────────────────────────── */
  .media-preview-overlay {
    position: fixed; inset: 0; z-index: 1000; background: rgba(4,5,8,.9);
    display: flex; align-items: center; justify-content: center; backdrop-filter: blur(3px);
  }
  .media-preview-close {
    position: absolute; top: 20px; right: 24px; margin: 0; padding: 8px 12px;
    background: var(--card-2); border: 1px solid var(--border); box-shadow: none; color: var(--text);
  }

  /* ── Upload progress ──────────────────────────────────────────────────── */
  .progress-wrap {
    margin-top: 10px; height: 8px; border-radius: 4px; background: var(--input);
    border: 1px solid var(--border); overflow: hidden;
  }
  .progress-bar {
    height: 100%; width: 0%; background: linear-gradient(90deg, var(--accent), var(--accent-cyan));
    transition: width .15s ease;
  }

  /* ── Login ─────────────────────────────────────────────────────────── */
  #login { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
  .login-card { width: 100%; max-width: 340px; text-align: center; }
  .login-logo {
    width: 52px; height: 52px; margin: 0 auto 18px; border-radius: 14px;
    background: linear-gradient(135deg, var(--accent), var(--accent-2));
    display: flex; align-items: center; justify-content: center;
    font-weight: 800; font-size: 22px; color: white;
    box-shadow: 0 10px 28px -8px var(--accent-glow);
  }
  .login-card h2 { text-transform: none; letter-spacing: 0; font-size: 19px; color: var(--text); margin-bottom: 2px; }
  .login-card label { text-align: left; }
  .login-card button { width: 100%; }

  /* ── Mobile (phone/narrow tablet) ─────────────────────────────────────── */
  @media (max-width: 880px) {
    .topbar {
      display: flex; align-items: center; gap: 12px; position: fixed; top: 0; left: 0; right: 0; height: 58px;
      background: var(--sidebar-bg); border-bottom: 1px solid var(--border); padding: 0 14px; z-index: 220;
    }
    .topbar-menu-btn {
      margin: 0; padding: 8px 10px; background: var(--card-2); border: 1px solid var(--border);
      box-shadow: none; font-size: 16px; line-height: 1;
    }
    .topbar-brand { font-weight: 800; font-size: 14px; }
    .topbar .dot { margin-left: auto; margin-right: 0; }
    .shell { display: block; }
    main { padding: 16px; padding-top: calc(58px + 20px); }
    .sidebar {
      position: fixed; top: 0; left: 0; height: 100vh; z-index: 250; width: 260px;
      transform: translateX(-100%); transition: transform .22s ease; box-shadow: 24px 0 48px rgba(0,0,0,.5);
    }
    .sidebar.open { transform: translateX(0); }
    .sidebar-backdrop.open {
      display: block; position: fixed; inset: 0; background: rgba(4,5,8,.6); z-index: 240;
    }
    .card, .card-grid .card { padding: 18px; }
    .card-grid { grid-template-columns: 1fr; gap: 14px; }
    .field-half { flex-direction: column; gap: 0; }
    h1 { font-size: 19px; }
    table { min-width: 420px; }
  }
</style>
</head>
<body>

<div id="login">
  <div class="card login-card">
    <div class="login-logo">M</div>
    <h2>MinePOS Shop Manager</h2>
    <p class="sub" style="margin-bottom:16px;">Sign in with your owner account</p>
    <label>Username</label>
    <input id="loginUser" autocomplete="username">
    <label>Password</label>
    <input id="loginPass" type="password" autocomplete="current-password">
    <button id="loginBtn" onclick="doLogin()">Sign in</button>
    <div id="loginMsg" class="msg"></div>
  </div>
</div>

<div id="app">
  <div class="topbar">
    <button class="topbar-menu-btn" onclick="toggleSidebar()">☰</button>
    <span class="topbar-brand">MinePOS</span>
    <span id="statusDotMobile" class="dot"></span>
  </div>
  <div class="sidebar-backdrop" onclick="toggleSidebar()"></div>
  <div class="shell">
    <nav class="sidebar">
      <div class="brand">
        <span class="login-logo" style="width:32px;height:32px;border-radius:9px;font-size:14px;">M</span>
        <div>
          <div class="brand-name" id="shopName">MinePOS</div>
          <div class="brand-sub">Shop Manager</div>
        </div>
        <span id="statusDot" class="dot" style="margin-left:auto;"></span>
      </div>
      <div class="sidebar-divider"></div>
      <div class="nav-group">
        <button class="navbtn active" data-sec="dashboard" onclick="showSection('dashboard')"><span class="sub-nav-icon">📊</span>Dashboard</button>
        <button class="navbtn" data-sec="menu" onclick="showSection('menu')"><span class="sub-nav-icon">🍔</span>Menu</button>
        <button class="navbtn" data-sec="staff" onclick="showSection('staff')"><span class="sub-nav-icon">👥</span>Staff</button>
        <button class="navbtn" data-sec="promotions" onclick="showSection('promotions')"><span class="sub-nav-icon">🏷️</span>Promotions</button>
        <button class="navbtn" data-sec="reports" onclick="showSection('reports')"><span class="sub-nav-icon">📈</span>Reports</button>
        <button class="navbtn" data-sec="shop" onclick="showSection('shop')"><span class="sub-nav-icon">⚙️</span>Shop Settings</button>
        <button class="navbtn" data-sec="ads" onclick="showSection('ads')"><span class="sub-nav-icon">📺</span>Advertising</button>
      </div>
      <div class="sidebar-footer">
        <div class="sidebar-divider" style="margin-top:0;"></div>
        <button class="navbtn" onclick="logout()" style="color:var(--danger-soft);"><span class="sub-nav-icon">🚪</span>Sign out</button>
      </div>
    </nav>
    <main>

      <section id="sec-dashboard" class="active">
        <div class="page-head">
          <h1>Dashboard</h1>
          <p class="sub" style="margin:0;">Signed in as <span id="whoami"></span></p>
        </div>

        <div class="card-grid" style="margin-bottom:18px;">
          <div class="card">
            <h2>Live Activity</h2>
            <div id="displaysLine" class="sub" style="margin-bottom:8px;"></div>
            <ul id="userList"></ul>
          </div>

          <div class="card">
            <h2>Listen Settings</h2>
            <div class="field-half">
              <div>
                <label>Port</label>
                <input id="cfgPort" type="number" min="1" max="65535">
              </div>
              <div>
                <label>Bind address</label>
                <select id="cfgBindMode" onchange="onBindModeChange()">
                  <option value="any">All interfaces (recommended)</option>
                  <option value="specific">Specific IP</option>
                </select>
              </div>
            </div>
            <div id="cfgIpWrap" class="hidden">
              <label>IP address</label>
              <input id="cfgIp" placeholder="192.168.1.50">
            </div>
            <button onclick="saveConfig()">Save &amp; restart</button>
            <div id="cfgMsg" class="msg"></div>
          </div>

          <div class="card">
            <h2>Server</h2>
            <button class="danger" onclick="restart()">Restart server</button>
            <div id="restartMsg" class="msg"></div>
          </div>
        </div>

        <div class="card" style="max-width:1080px;">
          <div class="row"><h2 style="margin:0;">Logs (last 300 lines)</h2>
            <button class="secondary small" onclick="loadLogs()">Refresh</button>
          </div>
          <pre id="logBox" style="margin-top:12px;"></pre>
        </div>
      </section>

      <section id="sec-menu">
        <h1>Menu</h1>
        <div class="card" style="max-width:960px;">
          <div class="row">
            <div id="menuCategoryChips"></div>
            <button onclick="openMenuForm(null)">Add Item</button>
          </div>
          <div class="table-wrap">
            <table>
              <thead><tr><th></th><th>Name</th><th>Category</th><th>Price</th><th>Available</th><th></th></tr></thead>
              <tbody id="menuTableBody"></tbody>
            </table>
          </div>
        </div>

        <div id="menuFormCard" class="card hidden">
          <h2 id="menuFormTitle">Add Item</h2>
          <label>Name</label>
          <input id="menuName">
          <label>Name (Thai, optional)</label>
          <input id="menuNameTh">
          <label>Category</label>
          <input id="menuCategory" list="menuCategoryList">
          <datalist id="menuCategoryList"></datalist>
          <div class="field-half">
            <div>
              <label>Price (฿)</label>
              <input id="menuPrice" type="number" min="0" step="0.01">
            </div>
          </div>
          <label style="margin-top:14px;"><input type="checkbox" id="menuAvailable" checked> Available</label>
          <label><input type="checkbox" id="menuHasSweetness"> Has sweetness levels (Less/Normal/Sweet)</label>
          <label>Photo (optional)</label>
          <input id="menuImageFile" type="file" accept="image/*">
          <div class="row" style="margin-top:14px;">
            <button onclick="saveMenuItem()">Save</button>
            <button class="secondary" onclick="closeMenuForm()">Cancel</button>
          </div>
          <div id="menuFormMsg" class="msg"></div>
        </div>
      </section>

      <section id="sec-staff">
        <h1>Staff</h1>
        <div class="card" style="max-width:960px;">
          <div class="row"><div></div><button onclick="openStaffForm(null)">Add Staff</button></div>
          <div class="table-wrap">
            <table>
              <thead><tr><th>Name</th><th>Username</th><th>Role</th><th>Active</th><th>Joined</th><th></th></tr></thead>
              <tbody id="staffTableBody"></tbody>
            </table>
          </div>
        </div>

        <div id="staffFormCard" class="card hidden">
          <h2 id="staffFormTitle">Add Staff</h2>
          <label>Username</label>
          <input id="staffUsername">
          <label id="staffPasswordLabel">Password</label>
          <input id="staffPassword" type="password">
          <label>Role</label>
          <select id="staffRole">
            <option value="worker">Employee</option>
            <option value="manager">Manager</option>
            <option value="owner">Owner</option>
          </select>
          <label>Display name (optional)</label>
          <input id="staffName">
          <label>Email (optional)</label>
          <input id="staffEmail">
          <label>Phone (optional)</label>
          <input id="staffPhone">
          <div id="staffActiveWrap" class="hidden">
            <label><input type="checkbox" id="staffActive"> Active</label>
          </div>
          <div id="staffRenameWrap" class="hidden">
            <h3>Change username</h3>
            <label>New username</label>
            <input id="staffNewUsername">
            <label>Your own password (required to confirm a rename)</label>
            <input id="staffConfirmPassword" type="password">
          </div>
          <div class="row" style="margin-top:14px;">
            <button onclick="saveStaff()">Save</button>
            <button class="secondary" onclick="closeStaffForm()">Cancel</button>
          </div>
          <div id="staffFormMsg" class="msg"></div>
        </div>
      </section>

      <section id="sec-promotions">
        <h1>Promotions</h1>
        <div class="card" style="max-width:960px;">
          <div class="row"><div></div><button onclick="openPromoForm(null)">Add Promotion</button></div>
          <div class="table-wrap">
            <table>
              <thead><tr><th></th><th>Name</th><th>Type</th><th>Scope</th><th></th></tr></thead>
              <tbody id="promoTableBody"></tbody>
            </table>
          </div>
        </div>

        <div id="promoFormCard" class="card hidden" style="max-width:640px;">
          <h2 id="promoFormTitle">Add Promotion</h2>
          <label>Name</label>
          <input id="promoName">
          <label><input type="checkbox" id="promoActive" checked> Active</label>

          <h3>Type</h3>
          <div id="promoTypeChips"></div>

          <div id="promoScopeWrap">
            <h3>Applies to</h3>
            <div id="promoScopeChips"></div>
            <div id="promoScopeCategoryWrap" class="hidden">
              <label>Category</label>
              <select id="promoScopeCategory"></select>
            </div>
            <div id="promoScopeItemsWrap" class="hidden">
              <label>Items</label>
              <div id="promoScopeItemsList" class="item-checklist"></div>
            </div>
            <div id="promoExcludeItemsWrap" class="hidden">
              <label>Exclude specific items (optional)</label>
              <div id="promoExcludeItemsList" class="item-checklist"></div>
            </div>
          </div>

          <div id="promoComboWrap" class="hidden">
            <h3>Combo</h3>
            <label>Bundle price (฿)</label>
            <input id="promoComboPrice" type="number" min="0" step="0.01">
            <label>Items included in the bundle</label>
            <div id="promoComboItemsList" class="item-checklist"></div>
          </div>

          <div id="promoPercentWrap" class="hidden">
            <h3>Percent off</h3>
            <label>Percent (%)</label>
            <input id="promoPercentValue" type="number" min="0" max="100" step="0.1">
            <label>Max discount amount (optional, ฿)</label>
            <input id="promoMaxCap" type="number" min="0" step="0.01">
          </div>

          <div id="promoFlatWrap" class="hidden">
            <h3>Flat amount off</h3>
            <label>Amount off (฿)</label>
            <input id="promoFlatAmount" type="number" min="0" step="0.01">
          </div>

          <div id="promoBogoWrap" class="hidden">
            <h3>Buy one get one</h3>
            <div class="field-half">
              <div><label>Buy quantity</label><input id="promoBogoBuyQty" type="number" min="1" value="2"></div>
              <div><label>Get quantity</label><input id="promoBogoGetQty" type="number" min="1" value="1"></div>
            </div>
            <label>Discount on the "get" items (%, 100 = free)</label>
            <input id="promoBogoDiscountPercent" type="number" min="0" max="100" value="100">
          </div>

          <div id="promoMinSpendWrap" class="hidden">
            <h3>Minimum spend</h3>
            <label>Minimum order total (฿)</label>
            <input id="promoMinSpendAmount" type="number" min="0" step="0.01">
          </div>

          <div id="promoRewardKindWrap" class="hidden">
            <h3>Reward</h3>
            <div id="promoRewardKindChips"></div>
            <div id="promoRewardPercentWrap">
              <label>Percent (%)</label>
              <input id="promoRewardPercentValue" type="number" min="0" max="100" step="0.1">
            </div>
            <div id="promoRewardFlatWrap" class="hidden">
              <label>Amount off (฿)</label>
              <input id="promoRewardFlatValue" type="number" min="0" step="0.01">
            </div>
          </div>

          <div id="promoTieredWrap" class="hidden">
            <h3>Quantity / price tiers</h3>
            <div id="promoTieredRows"></div>
            <button class="secondary small" onclick="addTieredRow()">+ Add tier</button>
          </div>

          <h3>Schedule (optional)</h3>
          <div class="field-half">
            <div><label>Start date</label><input id="promoStartDate" type="date"></div>
            <div><label>End date</label><input id="promoEndDate" type="date"></div>
          </div>
          <label>Days of week (leave all unchecked for every day)</label>
          <div id="promoDaysChips"></div>
          <div class="field-half">
            <div><label>Start time</label><input id="promoTimeStart" type="time"></div>
            <div><label>End time</label><input id="promoTimeEnd" type="time"></div>
          </div>

          <h3>Manager approval</h3>
          <label><input type="checkbox" id="promoRequiresApproval" onchange="onApprovalToggle()"> Requires manager approval</label>
          <div id="promoApprovalThresholdWrap" class="hidden">
            <label>Only above this discount amount (optional, ฿)</label>
            <input id="promoApprovalThreshold" type="number" min="0" step="0.01">
          </div>

          <div id="promoCodesWrap" class="hidden">
            <h3>Codes</h3>
            <ul id="promoCodesList"></ul>
            <div class="field-half">
              <div><label>New code</label><input id="promoNewCode"></div>
              <div><label>Max uses (optional)</label><input id="promoNewCodeMaxUses" type="number" min="1"></div>
            </div>
            <button class="secondary small" onclick="addPromoCode()">Add Code</button>
          </div>

          <div class="row" style="margin-top:14px;">
            <button onclick="savePromo()">Save</button>
            <button class="secondary" onclick="closePromoForm()">Cancel</button>
          </div>
          <div id="promoFormMsg" class="msg"></div>
        </div>
      </section>

      <section id="sec-reports">
        <h1>Reports</h1>
        <div id="reportsRangeChips"></div>
        <div id="reportsCustomWrap" class="card hidden" style="max-width:400px;">
          <div class="field-half">
            <div><label>From</label><input id="reportsCustomFrom" type="date"></div>
            <div><label>To</label><input id="reportsCustomTo" type="date"></div>
          </div>
          <button class="small" onclick="applyCustomRange()">Apply</button>
        </div>

        <div class="stat-grid" id="reportsStats"></div>

        <div class="card">
          <div class="row"><h2 style="margin:0;">Orders</h2>
            <button class="secondary small" onclick="exportCsv()">Export CSV</button>
          </div>
          <div class="table-wrap">
            <table>
              <thead><tr><th>#</th><th>Date</th><th>Staff</th><th>Payment</th><th>Discount</th><th>Total</th></tr></thead>
              <tbody id="reportsOrdersBody"></tbody>
            </table>
          </div>
        </div>

        <div class="card">
          <h2>Top Selling Items</h2>
          <ul id="reportsTopItems"></ul>
        </div>
        <div class="card">
          <h2>Sales by Staff</h2>
          <ul id="reportsStaffSales"></ul>
        </div>
        <div class="card">
          <h2>Promotions Used</h2>
          <ul id="reportsPromoBreakdown"></ul>
        </div>
      </section>

      <section id="sec-shop">
        <h1>Shop Settings</h1>
        <div class="card">
          <label>Shop name</label>
          <input id="shopNameField">
          <label>Address (optional)</label>
          <textarea id="shopAddress"></textarea>
          <label>Tax ID (optional)</label>
          <input id="shopTaxId">
          <label>Contact email (optional)</label>
          <input id="shopEmail">
          <label>Receipt footer (optional)</label>
          <textarea id="shopReceiptFooter"></textarea>
          <label>PromptPay ID (phone or tax ID, optional)</label>
          <input id="shopPromptPayId">
          <label>PromptPay label (optional)</label>
          <input id="shopPromptPayLabel">
          <button onclick="saveShop()">Save</button>
          <div id="shopFormMsg" class="msg"></div>
        </div>
      </section>

      <section id="sec-ads">
        <h1>Advertising</h1>
        <p class="sub">Plays on the customer-facing display whenever it's idle. Recommended size: 1920×1080 (16:9).</p>
        <div class="card" style="max-width:760px;">
          <div id="adsList"></div>
          <h3>Add slide</h3>
          <label>File (image, GIF, or video)</label>
          <input id="adsFile" type="file" accept="image/*,video/*">
          <label>Seconds to show (images/GIFs only, ignored for video)</label>
          <input id="adsDuration" type="number" min="1" value="8">
          <button onclick="uploadAdSlide()">Upload</button>
          <div id="adsProgressWrap" class="progress-wrap hidden">
            <div id="adsProgressBar" class="progress-bar"></div>
          </div>
          <div id="adsMsg" class="msg"></div>
        </div>
      </section>

    </main>
  </div>
</div>

<div id="mediaPreviewOverlay" class="media-preview-overlay hidden" onclick="if (event.target === this) closeMediaPreview()">
  <button class="media-preview-close" onclick="closeMediaPreview()">✕</button>
  <div id="mediaPreviewContent"></div>
</div>

<script>
// ── Auth / shell ─────────────────────────────────────────────────────────
let token = localStorage.getItem('minepos_admin_token') || '';
let role = localStorage.getItem('minepos_admin_role') || '';
let pollTimer = null;

function authHeaders() { return { 'Authorization': 'Bearer ' + token }; }

async function api(method, path, body) {
  const opts = { method, headers: authHeaders() };
  if (body !== undefined) {
    opts.headers = { ...opts.headers, 'Content-Type': 'application/json' };
    opts.body = JSON.stringify(body);
  }
  const res = await fetch(path, opts);
  if (res.status === 401) { logout(); throw new Error('Signed out'); }
  if (res.status === 204) return null;
  const data = await res.json().catch(() => null);
  if (!res.ok) throw new Error((data && data.error) || ('Request failed (' + res.status + ')'));
  return data;
}

async function doLogin() {
  const username = document.getElementById('loginUser').value.trim();
  const password = document.getElementById('loginPass').value;
  const msg = document.getElementById('loginMsg');
  msg.textContent = ''; msg.className = 'msg';
  if (!username || !password) { msg.textContent = 'Enter username and password.'; msg.className = 'msg err'; return; }
  try {
    const res = await fetch('/auth/login', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password, deviceName: 'Shop Manager Web' })
    });
    const data = await res.json();
    if (!res.ok) { msg.textContent = data.error || 'Login failed.'; msg.className = 'msg err'; return; }
    if (data.role !== 'owner') { msg.textContent = 'Owner access required.'; msg.className = 'msg err'; return; }
    token = data.token; role = data.role;
    localStorage.setItem('minepos_admin_token', token);
    localStorage.setItem('minepos_admin_role', role);
    document.getElementById('whoami').textContent = data.username + ' (owner)';
    enterApp();
  } catch (e) {
    msg.textContent = 'Could not reach the server.'; msg.className = 'msg err';
  }
}

function logout() {
  token = ''; localStorage.removeItem('minepos_admin_token'); localStorage.removeItem('minepos_admin_role');
  if (pollTimer) clearInterval(pollTimer);
  document.getElementById('app').style.display = 'none';
  document.getElementById('login').style.display = 'flex';
}

function toggleSidebar() {
  document.querySelector('.sidebar').classList.toggle('open');
  document.querySelector('.sidebar-backdrop').classList.toggle('open');
}

function showSection(name) {
  for (const el of document.querySelectorAll('main section')) el.classList.remove('active');
  document.getElementById('sec-' + name).classList.add('active');
  for (const btn of document.querySelectorAll('.navbtn[data-sec]')) btn.classList.toggle('active', btn.dataset.sec === name);
  // Auto-close the mobile drawer after picking a section — harmless on
  // desktop, where these classes are never toggled on in the first place.
  document.querySelector('.sidebar').classList.remove('open');
  document.querySelector('.sidebar-backdrop').classList.remove('open');
  if (name === 'menu') loadMenu();
  if (name === 'staff') loadStaff();
  // Promotions' scope pickers (item checklist, category dropdown) need
  // `menuItems` loaded regardless of whether the Menu section was visited
  // first this session.
  if (name === 'promotions') loadMenu().then(loadPromotions);
  if (name === 'reports') loadReports();
  if (name === 'shop') loadShop();
  if (name === 'ads') loadAds();
}

function enterApp() {
  document.getElementById('login').style.display = 'none';
  document.getElementById('app').style.display = 'block';
  loadConfig(); loadLogs(); poll();
  pollTimer = setInterval(poll, 5000);
}

function setStatusDot(cls) {
  for (const id of ['statusDot', 'statusDotMobile']) {
    const el = document.getElementById(id);
    if (el) el.className = cls;
  }
}

async function poll() {
  try {
    const health = await (await fetch('/health')).json();
    document.getElementById('shopName').textContent = health.shopName || 'MinePOS';
    setStatusDot('dot live');
  } catch (e) {
    setStatusDot('dot off');
    return;
  }
  try {
    const data = await api('GET', '/admin/presence');
    document.getElementById('displaysLine').textContent =
      `${data.kitchenDisplays} kitchen display(s), ${data.customerDisplays} customer display(s) connected`;
    const list = document.getElementById('userList');
    list.innerHTML = '';
    if (data.onlineUsers.length === 0) {
      list.innerHTML = '<li class="sub">No one online right now.</li>';
    }
    for (const u of data.onlineUsers) {
      const li = document.createElement('li');
      li.innerHTML = `${u.username} <span class="role">${u.role} · ${u.deviceName}</span>`;
      list.appendChild(li);
    }
  } catch (e) {}
}

async function loadConfig() {
  try {
    const data = await api('GET', '/admin/config');
    document.getElementById('cfgPort').value = data.port;
    if (data.bindAddress === 'any') {
      document.getElementById('cfgBindMode').value = 'any';
    } else {
      document.getElementById('cfgBindMode').value = 'specific';
      document.getElementById('cfgIp').value = data.bindAddress;
    }
    onBindModeChange();
  } catch (e) {}
}

function onBindModeChange() {
  document.getElementById('cfgIpWrap').classList.toggle('hidden', document.getElementById('cfgBindMode').value !== 'specific');
}

async function saveConfig() {
  const msg = document.getElementById('cfgMsg');
  const port = parseInt(document.getElementById('cfgPort').value, 10);
  const mode = document.getElementById('cfgBindMode').value;
  const ip = document.getElementById('cfgIp').value.trim();
  if (!port || port < 1 || port > 65535) { msg.textContent = 'Enter a valid port.'; msg.className = 'msg err'; return; }
  if (mode === 'specific' && !ip) { msg.textContent = 'Enter an IP address.'; msg.className = 'msg err'; return; }
  if (!confirm('This restarts the server now. Other connected devices will briefly drop, and if you change the port or IP you will need to reload this page at the new address. Continue?')) return;
  try {
    await api('PATCH', '/admin/config', { port, bindAddress: mode === 'any' ? 'any' : ip });
    msg.textContent = 'Saved — server is restarting. Reload this page at the new address/port if it changed.';
    msg.className = 'msg ok';
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

async function restart() {
  const msg = document.getElementById('restartMsg');
  if (!confirm('Restart the server now? Other connected devices will briefly drop.')) return;
  try {
    await api('POST', '/admin/restart');
    msg.textContent = 'Restart requested.'; msg.className = 'msg ok';
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

async function loadLogs() {
  try {
    const res = await fetch('/admin/logs?lines=300', { headers: authHeaders() });
    if (res.status === 401) { logout(); return; }
    const data = await res.json();
    const box = document.getElementById('logBox');
    box.textContent = data.lines.join('\n');
    box.scrollTop = box.scrollHeight;
  } catch (e) {}
}

// ── Shared helpers ───────────────────────────────────────────────────────

function esc(s) {
  const d = document.createElement('div'); d.textContent = s == null ? '' : String(s); return d.innerHTML;
}
function baht(v) { return '฿' + Number(v || 0).toFixed(0); }
function fileToBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result.split(',')[1]);
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}
function chip(container, value, label, selected, onClick) {
  const el = document.createElement('div');
  el.className = 'chip' + (selected ? ' sel' : '');
  el.textContent = label;
  el.onclick = () => onClick(value);
  container.appendChild(el);
}

// ── Menu ─────────────────────────────────────────────────────────────────
let menuItems = [];
let menuCategoryFilter = 'All';
let menuEditingId = null;

async function loadMenu() {
  try { menuItems = await api('GET', '/menu'); } catch (e) { menuItems = []; }
  renderMenuCategoryChips();
  renderMenuTable();
}

function renderMenuCategoryChips() {
  const cats = ['All', ...new Set(menuItems.map(i => i.category))];
  const container = document.getElementById('menuCategoryChips');
  container.innerHTML = '';
  for (const c of cats) chip(container, c, c, c === menuCategoryFilter, (v) => { menuCategoryFilter = v; renderMenuTable(); });
  const datalist = document.getElementById('menuCategoryList');
  datalist.innerHTML = cats.filter(c => c !== 'All').map(c => `<option value="${esc(c)}">`).join('');
}

function renderMenuTable() {
  const body = document.getElementById('menuTableBody');
  const items = menuCategoryFilter === 'All' ? menuItems : menuItems.filter(i => i.category === menuCategoryFilter);
  body.innerHTML = items.map(i => `
    <tr>
      <td>${i.imageBase64 ? `<img class="thumb" src="data:image/png;base64,${i.imageBase64}">` : ''}</td>
      <td>${esc(i.name)}</td>
      <td>${esc(i.category)}</td>
      <td>${baht(i.price)}</td>
      <td><div class="toggle-track ${i.available ? 'on' : ''}" onclick="toggleMenuItem('${i.id}')"><div class="knob"></div></div></td>
      <td>
        <button class="small secondary" onclick="openMenuForm('${i.id}')">Edit</button>
        <button class="small danger" onclick="deleteMenuItem('${i.id}')">Delete</button>
      </td>
    </tr>
  `).join('');
}

function openMenuForm(id) {
  menuEditingId = id;
  const item = id ? menuItems.find(i => i.id === id) : null;
  document.getElementById('menuFormTitle').textContent = item ? 'Edit Item' : 'Add Item';
  document.getElementById('menuName').value = item ? item.name : '';
  document.getElementById('menuNameTh').value = item ? (item.nameTh || '') : '';
  document.getElementById('menuCategory').value = item ? item.category : '';
  document.getElementById('menuPrice').value = item ? item.price : '';
  document.getElementById('menuAvailable').checked = item ? item.available : true;
  document.getElementById('menuHasSweetness').checked = item ? item.hasSweetness : false;
  document.getElementById('menuImageFile').value = '';
  document.getElementById('menuFormMsg').textContent = '';
  document.getElementById('menuFormCard').classList.remove('hidden');
}
function closeMenuForm() { document.getElementById('menuFormCard').classList.add('hidden'); }

async function saveMenuItem() {
  const msg = document.getElementById('menuFormMsg');
  const name = document.getElementById('menuName').value.trim();
  const category = document.getElementById('menuCategory').value.trim();
  const price = parseFloat(document.getElementById('menuPrice').value);
  if (!name || !category || !(price > 0)) { msg.textContent = 'Name, category, and a price above 0 are required.'; msg.className = 'msg err'; return; }
  const file = document.getElementById('menuImageFile').files[0];
  const existing = menuEditingId ? menuItems.find(i => i.id === menuEditingId) : null;
  const body = {
    name, category, price,
    available: document.getElementById('menuAvailable').checked,
    hasSweetness: document.getElementById('menuHasSweetness').checked,
    nameTh: document.getElementById('menuNameTh').value.trim() || null,
    imageBase64: file ? await fileToBase64(file) : (existing ? existing.imageBase64 : null),
  };
  try {
    if (menuEditingId) await api('PUT', '/menu/' + menuEditingId, body);
    else await api('POST', '/menu', body);
    closeMenuForm(); loadMenu();
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

async function toggleMenuItem(id) { try { await api('PATCH', '/menu/' + id + '/toggle'); loadMenu(); } catch (e) {} }
async function deleteMenuItem(id) {
  if (!confirm('Delete this menu item? This cannot be undone.')) return;
  try { await api('DELETE', '/menu/' + id); loadMenu(); } catch (e) { alert(e.message); }
}

// ── Staff ────────────────────────────────────────────────────────────────
let staffList = [];
let staffEditingId = null;

async function loadStaff() {
  try { staffList = await api('GET', '/users'); } catch (e) { staffList = []; }
  renderStaffTable();
}

function renderStaffTable() {
  const body = document.getElementById('staffTableBody');
  body.innerHTML = staffList.map(u => `
    <tr>
      <td>${esc(u.name || u.username)}</td>
      <td>@${esc(u.username)}</td>
      <td><span class="badge" style="background:#2a2e3a;">${esc(u.role)}</span></td>
      <td><div class="toggle-track ${u.active ? 'on' : ''}" onclick="toggleStaffActive(${u.id}, ${u.active})"><div class="knob"></div></div></td>
      <td>${esc(new Date(u.createdAt).toLocaleDateString())}</td>
      <td>
        <button class="small secondary" onclick="openStaffForm(${u.id})">Edit</button>
        <button class="small secondary" onclick="forceLogoutStaff(${u.id})">Sign out</button>
        <button class="small danger" onclick="deleteStaff(${u.id})">Delete</button>
      </td>
    </tr>
  `).join('');
}

function openStaffForm(id) {
  staffEditingId = id;
  const u = id ? staffList.find(s => s.id === id) : null;
  document.getElementById('staffFormTitle').textContent = u ? 'Edit Staff' : 'Add Staff';
  document.getElementById('staffUsername').value = u ? u.username : '';
  document.getElementById('staffUsername').disabled = !!u;
  document.getElementById('staffPasswordLabel').textContent = u ? 'New password (optional)' : 'Password';
  document.getElementById('staffPassword').value = '';
  document.getElementById('staffRole').value = u ? u.role : 'worker';
  document.getElementById('staffName').value = u ? (u.name || '') : '';
  document.getElementById('staffEmail').value = u ? (u.email || '') : '';
  document.getElementById('staffPhone').value = u ? (u.phone || '') : '';
  document.getElementById('staffActiveWrap').classList.toggle('hidden', !u);
  document.getElementById('staffActive').checked = u ? u.active : true;
  document.getElementById('staffRenameWrap').classList.toggle('hidden', !u);
  document.getElementById('staffNewUsername').value = '';
  document.getElementById('staffConfirmPassword').value = '';
  document.getElementById('staffFormMsg').textContent = '';
  document.getElementById('staffFormCard').classList.remove('hidden');
}
function closeStaffForm() { document.getElementById('staffFormCard').classList.add('hidden'); }

async function saveStaff() {
  const msg = document.getElementById('staffFormMsg');
  try {
    if (!staffEditingId) {
      const username = document.getElementById('staffUsername').value.trim();
      const password = document.getElementById('staffPassword').value;
      if (!username) { msg.textContent = 'Username is required.'; msg.className = 'msg err'; return; }
      if (!password || password.length < 8) { msg.textContent = 'Password must be at least 8 characters.'; msg.className = 'msg err'; return; }
      await api('POST', '/users', {
        username, password, role: document.getElementById('staffRole').value,
        name: document.getElementById('staffName').value.trim() || null,
        email: document.getElementById('staffEmail').value.trim() || null,
        phone: document.getElementById('staffPhone').value.trim() || null,
      });
    } else {
      const body = {
        role: document.getElementById('staffRole').value,
        active: document.getElementById('staffActive').checked,
        name: document.getElementById('staffName').value.trim() || null,
        email: document.getElementById('staffEmail').value.trim() || null,
        phone: document.getElementById('staffPhone').value.trim() || null,
      };
      const newPassword = document.getElementById('staffPassword').value;
      if (newPassword) {
        if (newPassword.length < 8) { msg.textContent = 'Password must be at least 8 characters.'; msg.className = 'msg err'; return; }
        body.password = newPassword;
      }
      const newUsername = document.getElementById('staffNewUsername').value.trim();
      if (newUsername) {
        body.username = newUsername;
        body.confirmPassword = document.getElementById('staffConfirmPassword').value;
      }
      await api('PATCH', '/users/' + staffEditingId, body);
    }
    closeStaffForm(); loadStaff();
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

async function toggleStaffActive(id, current) {
  try { await api('PATCH', '/users/' + id, { active: !current }); loadStaff(); } catch (e) { alert(e.message); }
}
async function forceLogoutStaff(id) {
  try { await api('POST', '/users/' + id + '/logout'); alert('Signed out on all devices.'); } catch (e) { alert(e.message); }
}
async function deleteStaff(id) {
  if (!confirm('Remove this staff member? This cannot be undone.')) return;
  try { await api('DELETE', '/users/' + id); loadStaff(); } catch (e) { alert(e.message); }
}

// ── Promotions ───────────────────────────────────────────────────────────
const PROMO_TYPES = [
  ['percent', 'Percent off'], ['flat', 'Flat amount off'], ['bogo', 'Buy one get one'],
  ['code', 'Discount code'], ['combo', 'Combo bundle'], ['min_spend', 'Minimum spend'], ['tiered', 'Tiered pricing'],
];
let promoList = [];
let promoEditingId = null;
let promoType = 'percent';
let promoScopeType = 'shop';
let promoRewardKind = 'percent';
let promoScopeItemIds = new Set();
let promoExcludeItemIds = new Set();
let promoDaysOfWeek = new Set();
let promoTiered = [];
let promoCodes = [];

async function loadPromotions() {
  try { promoList = await api('GET', '/promotions'); } catch (e) { promoList = []; }
  renderPromoTable();
}

function renderPromoTable() {
  const body = document.getElementById('promoTableBody');
  body.innerHTML = promoList.map(p => `
    <tr>
      <td><div class="toggle-track ${p.active ? 'on' : ''}" onclick="togglePromoActive('${p.id}', ${p.active})"><div class="knob"></div></div></td>
      <td>${esc(p.name)}</td>
      <td>${esc(PROMO_TYPES.find(t => t[0] === p.type)?.[1] || p.type)}</td>
      <td>${esc(p.scopeType === 'category' ? (p.scopeCategory || 'category') : p.scopeType)}</td>
      <td>
        <button class="small secondary" onclick="openPromoForm('${p.id}')">Edit</button>
        <button class="small danger" onclick="deletePromo('${p.id}')">Delete</button>
      </td>
    </tr>
  `).join('');
}

async function togglePromoActive(id, current) {
  const p = promoList.find(x => x.id === id);
  try { await api('PATCH', '/promotions/' + id, { ...promoToBody(p), active: !current }); loadPromotions(); } catch (e) { alert(e.message); }
}

function promoToBody(p) {
  // Round-trips every field this page knows about — used both for the
  // active-toggle shortcut above and as the base for the real save below.
  return {
    name: p.name, type: p.type, active: p.active, scopeType: p.scopeType,
    scopeItemIds: p.scopeItemIds, scopeCategory: p.scopeCategory, excludeItemIds: p.excludeItemIds,
    percentValue: p.percentValue, flatAmount: p.flatAmount, maxDiscountCap: p.maxDiscountCap,
    minSpendAmount: p.minSpendAmount, bogoBuyQty: p.bogoBuyQty, bogoGetQty: p.bogoGetQty,
    bogoGetDiscountPercent: p.bogoGetDiscountPercent, comboPrice: p.comboPrice, tiered: p.tiered,
    startDate: p.startDate, endDate: p.endDate, daysOfWeek: p.daysOfWeek, timeStart: p.timeStart, timeEnd: p.timeEnd,
    requiresManagerApproval: p.requiresManagerApproval, approvalThresholdAmount: p.approvalThresholdAmount,
  };
}

function openPromoForm(id) {
  promoEditingId = id;
  const p = id ? promoList.find(x => x.id === id) : null;
  document.getElementById('promoFormTitle').textContent = p ? 'Edit Promotion' : 'Add Promotion';
  document.getElementById('promoName').value = p ? p.name : '';
  document.getElementById('promoActive').checked = p ? p.active : true;
  promoType = p ? p.type : 'percent';
  promoScopeType = p && p.type !== 'combo' ? p.scopeType : 'shop';
  promoRewardKind = p && p.flatAmount != null && p.percentValue == null ? 'flat' : 'percent';
  promoScopeItemIds = new Set(p ? p.scopeItemIds : []);
  promoExcludeItemIds = new Set(p ? p.excludeItemIds : []);
  promoDaysOfWeek = new Set(p ? (p.daysOfWeek || []) : []);
  promoTiered = p ? p.tiered.map(t => ({ qty: t.qty, price: t.price })) : [];
  promoCodes = p ? p.codes : [];

  document.getElementById('promoComboPrice').value = p ? (p.comboPrice ?? '') : '';
  document.getElementById('promoPercentValue').value = p ? (p.percentValue ?? '') : '';
  document.getElementById('promoMaxCap').value = p ? (p.maxDiscountCap ?? '') : '';
  document.getElementById('promoFlatAmount').value = p ? (p.flatAmount ?? '') : '';
  document.getElementById('promoBogoBuyQty').value = p ? (p.bogoBuyQty ?? 2) : 2;
  document.getElementById('promoBogoGetQty').value = p ? (p.bogoGetQty ?? 1) : 1;
  document.getElementById('promoBogoDiscountPercent').value = p ? (p.bogoGetDiscountPercent ?? 100) : 100;
  document.getElementById('promoMinSpendAmount').value = p ? (p.minSpendAmount ?? '') : '';
  document.getElementById('promoRewardPercentValue').value = p ? (p.percentValue ?? '') : '';
  document.getElementById('promoRewardFlatValue').value = p ? (p.flatAmount ?? '') : '';
  document.getElementById('promoStartDate').value = p && p.startDate ? p.startDate.substring(0, 10) : '';
  document.getElementById('promoEndDate').value = p && p.endDate ? p.endDate.substring(0, 10) : '';
  document.getElementById('promoTimeStart').value = p ? (p.timeStart || '') : '';
  document.getElementById('promoTimeEnd').value = p ? (p.timeEnd || '') : '';
  document.getElementById('promoRequiresApproval').checked = p ? p.requiresManagerApproval : false;
  document.getElementById('promoApprovalThreshold').value = p ? (p.approvalThresholdAmount ?? '') : '';
  onApprovalToggle();
  document.getElementById('promoCodesWrap').classList.toggle('hidden', !(p && p.type === 'code'));

  renderPromoTypeChips();
  renderPromoScopeChips();
  renderPromoRewardKindChips();
  renderPromoTieredRows();
  renderPromoCodesList();
  renderPromoItemChecklists();
  updatePromoTypeVisibility();
  document.getElementById('promoFormMsg').textContent = '';
  document.getElementById('promoFormCard').classList.remove('hidden');
}
function closePromoForm() { document.getElementById('promoFormCard').classList.add('hidden'); }

function renderPromoTypeChips() {
  const c = document.getElementById('promoTypeChips'); c.innerHTML = '';
  for (const [value, label] of PROMO_TYPES) {
    chip(c, value, label, value === promoType, (v) => { promoType = v; updatePromoTypeVisibility(); renderPromoTypeChips(); });
  }
}
function renderPromoScopeChips() {
  const c = document.getElementById('promoScopeChips'); c.innerHTML = '';
  for (const [value, label] of [['item', 'Specific item(s)'], ['category', 'Category'], ['shop', 'Whole shop']]) {
    chip(c, value, label, value === promoScopeType, (v) => { promoScopeType = v; updatePromoTypeVisibility(); renderPromoScopeChips(); });
  }
}
function renderPromoRewardKindChips() {
  const c = document.getElementById('promoRewardKindChips'); c.innerHTML = '';
  for (const [value, label] of [['percent', 'Percent off'], ['flat', 'Fixed amount off']]) {
    chip(c, value, label, value === promoRewardKind, (v) => {
      promoRewardKind = v;
      document.getElementById('promoRewardPercentWrap').classList.toggle('hidden', v !== 'percent');
      document.getElementById('promoRewardFlatWrap').classList.toggle('hidden', v !== 'flat');
      renderPromoRewardKindChips();
    });
  }
}
function renderPromoItemChecklists() {
  for (const [listId, set] of [['promoScopeItemsList', promoScopeItemIds], ['promoExcludeItemsList', promoExcludeItemIds], ['promoComboItemsList', promoScopeItemIds]]) {
    const el = document.getElementById(listId);
    el.innerHTML = menuItems.map(i => `
      <label><input type="checkbox" data-id="${i.id}" ${set.has(i.id) ? 'checked' : ''}
        onchange="onItemCheckChange('${listId}', '${i.id}', this.checked)"> ${esc(i.name)} <span style="color:#8b90a0;">(${esc(i.category)})</span></label>
    `).join('') || '<span class="sub">No menu items yet.</span>';
  }
  const catSel = document.getElementById('promoScopeCategory');
  const cats = [...new Set(menuItems.map(i => i.category))];
  const current = catSel.value;
  catSel.innerHTML = cats.map(c => `<option value="${esc(c)}">${esc(c)}</option>`).join('');
  if (promoEditingId) {
    const p = promoList.find(x => x.id === promoEditingId);
    if (p && p.scopeCategory) catSel.value = p.scopeCategory;
  } else if (current) catSel.value = current;
}
function onItemCheckChange(listId, id, checked) {
  const set = listId === 'promoExcludeItemsList' ? promoExcludeItemIds : promoScopeItemIds;
  if (checked) set.add(id); else set.delete(id);
}
function renderPromoTieredRows() {
  const c = document.getElementById('promoTieredRows');
  c.innerHTML = promoTiered.map((t, i) => `
    <div class="field-half" style="margin-bottom:8px;">
      <div><label>Qty</label><input type="number" min="1" value="${t.qty}" onchange="promoTiered[${i}].qty=parseInt(this.value,10)"></div>
      <div><label>Price (฿)</label><input type="number" min="0" step="0.01" value="${t.price}" onchange="promoTiered[${i}].price=parseFloat(this.value)"></div>
      <button class="small secondary" style="margin-top:20px;" onclick="promoTiered.splice(${i},1); renderPromoTieredRows();">Remove</button>
    </div>
  `).join('');
}
function addTieredRow() { promoTiered.push({ qty: 1, price: 0 }); renderPromoTieredRows(); }

function renderPromoDaysChips() {
  const c = document.getElementById('promoDaysChips'); c.innerHTML = '';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  days.forEach((label, idx) => chip(c, idx, label, promoDaysOfWeek.has(idx), (v) => {
    if (promoDaysOfWeek.has(v)) promoDaysOfWeek.delete(v); else promoDaysOfWeek.add(v);
    renderPromoDaysChips();
  }));
}

function renderPromoCodesList() {
  const list = document.getElementById('promoCodesList');
  list.innerHTML = promoCodes.map(c => `
    <li class="row"><span>${esc(c.code)} <span class="sub">(used ${c.usedCount}/${c.maxUses ?? '∞'})</span></span>
      <button class="small danger" onclick="deletePromoCode('${c.id}')">Delete</button></li>
  `).join('') || '<li class="sub">No codes yet.</li>';
}

function updatePromoTypeVisibility() {
  const isCombo = promoType === 'combo';
  document.getElementById('promoScopeWrap').classList.toggle('hidden', isCombo);
  document.getElementById('promoComboWrap').classList.toggle('hidden', !isCombo);
  document.getElementById('promoScopeCategoryWrap').classList.toggle('hidden', isCombo || promoScopeType !== 'category');
  document.getElementById('promoScopeItemsWrap').classList.toggle('hidden', isCombo || promoScopeType !== 'item');
  document.getElementById('promoExcludeItemsWrap').classList.toggle('hidden', isCombo || promoScopeType !== 'shop');
  document.getElementById('promoPercentWrap').classList.toggle('hidden', promoType !== 'percent');
  document.getElementById('promoFlatWrap').classList.toggle('hidden', promoType !== 'flat');
  document.getElementById('promoBogoWrap').classList.toggle('hidden', promoType !== 'bogo');
  document.getElementById('promoMinSpendWrap').classList.toggle('hidden', promoType !== 'min_spend');
  document.getElementById('promoRewardKindWrap').classList.toggle('hidden', !(promoType === 'code' || promoType === 'min_spend'));
  document.getElementById('promoTieredWrap').classList.toggle('hidden', promoType !== 'tiered');
  document.getElementById('promoCodesWrap').classList.toggle('hidden', !(promoType === 'code' && promoEditingId));
  renderPromoDaysChips();
}

function onApprovalToggle() {
  document.getElementById('promoApprovalThresholdWrap').classList.toggle('hidden', !document.getElementById('promoRequiresApproval').checked);
}

async function savePromo() {
  const msg = document.getElementById('promoFormMsg');
  const name = document.getElementById('promoName').value.trim();
  if (!name) { msg.textContent = 'Name is required.'; msg.className = 'msg err'; return; }
  const isCombo = promoType === 'combo';
  const usesReward = promoType === 'code' || promoType === 'min_spend';
  const body = {
    name, type: promoType, active: document.getElementById('promoActive').checked,
    scopeType: isCombo ? 'item' : promoScopeType,
    scopeItemIds: isCombo ? [...promoScopeItemIds] : (promoScopeType === 'item' ? [...promoScopeItemIds] : []),
    scopeCategory: !isCombo && promoScopeType === 'category' ? document.getElementById('promoScopeCategory').value : null,
    excludeItemIds: !isCombo && promoScopeType === 'shop' ? [...promoExcludeItemIds] : [],
    percentValue: promoType === 'percent' ? parseFloat(document.getElementById('promoPercentValue').value) || null
      : (usesReward && promoRewardKind === 'percent' ? parseFloat(document.getElementById('promoRewardPercentValue').value) || null : null),
    flatAmount: promoType === 'flat' ? parseFloat(document.getElementById('promoFlatAmount').value) || null
      : (usesReward && promoRewardKind === 'flat' ? parseFloat(document.getElementById('promoRewardFlatValue').value) || null : null),
    maxDiscountCap: promoType === 'percent' ? (parseFloat(document.getElementById('promoMaxCap').value) || null) : null,
    minSpendAmount: promoType === 'min_spend' ? parseFloat(document.getElementById('promoMinSpendAmount').value) || null : null,
    bogoBuyQty: promoType === 'bogo' ? parseInt(document.getElementById('promoBogoBuyQty').value, 10) || null : null,
    bogoGetQty: promoType === 'bogo' ? parseInt(document.getElementById('promoBogoGetQty').value, 10) || null : null,
    bogoGetDiscountPercent: promoType === 'bogo' ? parseFloat(document.getElementById('promoBogoDiscountPercent').value) || null : null,
    comboPrice: isCombo ? parseFloat(document.getElementById('promoComboPrice').value) || null : null,
    tiered: promoType === 'tiered' ? promoTiered : [],
    startDate: document.getElementById('promoStartDate').value ? document.getElementById('promoStartDate').value + 'T00:00:00' : null,
    endDate: document.getElementById('promoEndDate').value ? document.getElementById('promoEndDate').value + 'T00:00:00' : null,
    daysOfWeek: promoDaysOfWeek.size ? [...promoDaysOfWeek] : null,
    timeStart: document.getElementById('promoTimeStart').value || null,
    timeEnd: document.getElementById('promoTimeEnd').value || null,
    requiresManagerApproval: document.getElementById('promoRequiresApproval').checked,
    approvalThresholdAmount: parseFloat(document.getElementById('promoApprovalThreshold').value) || null,
  };
  try {
    if (promoEditingId) await api('PATCH', '/promotions/' + promoEditingId, body);
    else {
      const created = await api('POST', '/promotions', body);
      promoEditingId = created.id;
    }
    if (promoType === 'code') { await loadPromotions(); openPromoForm(promoEditingId); return; }
    closePromoForm(); loadPromotions();
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

async function deletePromo(id) {
  if (!confirm('Delete this promotion? This cannot be undone.')) return;
  try { await api('DELETE', '/promotions/' + id); loadPromotions(); } catch (e) { alert(e.message); }
}

async function addPromoCode() {
  const code = document.getElementById('promoNewCode').value.trim();
  if (!code || !promoEditingId) return;
  const maxUses = document.getElementById('promoNewCodeMaxUses').value ? parseInt(document.getElementById('promoNewCodeMaxUses').value, 10) : null;
  try {
    const created = await api('POST', '/promotions/' + promoEditingId + '/codes', { code, maxUses });
    promoCodes.push(created);
    document.getElementById('promoNewCode').value = ''; document.getElementById('promoNewCodeMaxUses').value = '';
    renderPromoCodesList();
  } catch (e) { alert(e.message); }
}
async function deletePromoCode(codeId) {
  try {
    await api('DELETE', '/promotions/' + promoEditingId + '/codes/' + codeId);
    promoCodes = promoCodes.filter(c => c.id !== codeId);
    renderPromoCodesList();
  } catch (e) { alert(e.message); }
}

// ── Reports ──────────────────────────────────────────────────────────────
let reportsOrders = [];
let reportsRange = 'today';
let reportsCustomFrom = null, reportsCustomTo = null;

async function loadReports() {
  try { reportsOrders = await api('GET', '/orders'); } catch (e) { reportsOrders = []; }
  renderReportsRangeChips();
  renderReports();
}

function renderReportsRangeChips() {
  const c = document.getElementById('reportsRangeChips'); c.innerHTML = '';
  const options = [['today', 'Today'], ['yesterday', 'Yesterday'], ['last7', 'Last 7 Days'], ['last30', 'Last 30 Days'],
    ['month', 'This Month'], ['all', 'All Time'], ['custom', 'Custom…']];
  for (const [value, label] of options) {
    chip(c, value, label, value === reportsRange, (v) => {
      reportsRange = v;
      document.getElementById('reportsCustomWrap').classList.toggle('hidden', v !== 'custom');
      renderReportsRangeChips(); renderReports();
    });
  }
}

function resolveReportsRange() {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const addDays = (d, n) => new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
  switch (reportsRange) {
    case 'today': return [today, addDays(today, 1)];
    case 'yesterday': return [addDays(today, -1), today];
    case 'last7': return [addDays(today, -6), addDays(today, 1)];
    case 'last30': return [addDays(today, -29), addDays(today, 1)];
    case 'month': return [new Date(now.getFullYear(), now.getMonth(), 1), new Date(now.getFullYear(), now.getMonth() + 1, 1)];
    case 'all': return [new Date(2000, 0, 1), addDays(today, 1)];
    case 'custom': return [reportsCustomFrom || today, reportsCustomTo ? addDays(reportsCustomTo, 1) : addDays(today, 1)];
  }
}
function applyCustomRange() {
  const from = document.getElementById('reportsCustomFrom').value;
  const to = document.getElementById('reportsCustomTo').value;
  reportsCustomFrom = from ? new Date(from) : null;
  reportsCustomTo = to ? new Date(to) : null;
  renderReports();
}

function renderReports() {
  const [start, end] = resolveReportsRange();
  const orders = reportsOrders.filter(o => {
    const d = new Date(o.createdAt);
    return o.status !== 'cancelled' && d >= start && d < end;
  });
  const revenue = orders.reduce((s, o) => s + o.total, 0);
  const discounted = orders.reduce((s, o) => s + (o.discountTotal || 0), 0);
  const cashCount = orders.filter(o => o.paymentMethod === 'cash').length;
  const avg = orders.length ? revenue / orders.length : 0;

  const stats = document.getElementById('reportsStats');
  stats.innerHTML = [
    ['Orders', orders.length], ['Revenue', baht(revenue)], ['Avg Order', orders.length ? baht(avg) : '—'],
    ['Cash', cashCount], ['PromptPay', orders.length - cashCount], ['Discounted', baht(discounted)],
  ].map(([l, v]) => `<div class="stat-card"><div class="v">${esc(v)}</div><div class="l">${esc(l).toUpperCase()}</div></div>`).join('');

  document.getElementById('reportsOrdersBody').innerHTML = orders.map(o => `
    <tr>
      <td>#${String(o.orderNumber).padStart(3, '0')}</td>
      <td>${esc(new Date(o.createdAt).toLocaleString())}</td>
      <td>${esc(o.createdByName || '—')}</td>
      <td>${o.paymentMethod === 'cash' ? 'Cash' : 'PromptPay'}</td>
      <td>${o.discountTotal ? '-' + baht(o.discountTotal) : '—'}</td>
      <td>${baht(o.total)}</td>
    </tr>
  `).join('') || '<tr><td colspan="6" class="sub">No orders in this range.</td></tr>';

  const itemTotals = {};
  for (const o of orders) for (const it of o.items) {
    const prev = itemTotals[it.menuItemName] || { qty: 0, revenue: 0 };
    itemTotals[it.menuItemName] = { qty: prev.qty + it.quantity, revenue: prev.revenue + it.price * it.quantity };
  }
  renderRankedList('reportsTopItems', Object.entries(itemTotals).sort((a, b) => b[1].revenue - a[1].revenue).slice(0, 5),
    (name, v) => `${esc(name)} <span class="sub">${v.qty} sold</span> — ${baht(v.revenue)}`);

  const staffTotals = {};
  for (const o of orders) {
    const name = o.createdByName || 'Unknown';
    const prev = staffTotals[name] || { count: 0, revenue: 0 };
    staffTotals[name] = { count: prev.count + 1, revenue: prev.revenue + o.total };
  }
  renderRankedList('reportsStaffSales', Object.entries(staffTotals).sort((a, b) => b[1].revenue - a[1].revenue),
    (name, v) => `${esc(name)} <span class="sub">${v.count} orders</span> — ${baht(v.revenue)}`);

  const promoTotals = {};
  for (const o of orders) for (const p of (o.appliedPromotions || [])) {
    const prev = promoTotals[p.name] || { count: 0, discount: 0 };
    promoTotals[p.name] = { count: prev.count + 1, discount: prev.discount + p.discountAmount };
  }
  renderRankedList('reportsPromoBreakdown', Object.entries(promoTotals).sort((a, b) => b[1].discount - a[1].discount),
    (name, v) => `${esc(name)} <span class="sub">${v.count} used</span> — -${baht(v.discount)}`);
}

function renderRankedList(elId, entries, fmt) {
  const el = document.getElementById(elId);
  el.innerHTML = entries.map(([name, v]) => `<li>${fmt(name, v)}</li>`).join('') || '<li class="sub">Nothing in this range.</li>';
}

function exportCsv() {
  const [start, end] = resolveReportsRange();
  const orders = reportsOrders.filter(o => { const d = new Date(o.createdAt); return o.status !== 'cancelled' && d >= start && d < end; });
  const rows = [['Order', 'Date', 'Item', 'Quantity', 'Unit Price', 'Subtotal', 'Payment Method', 'Staff', 'Discount', 'Order Total']];
  for (const o of orders) {
    for (const it of o.items) {
      rows.push(['#' + String(o.orderNumber).padStart(3, '0'), new Date(o.createdAt).toLocaleString(),
        it.menuItemName, it.quantity, it.price.toFixed(2), (it.price * it.quantity).toFixed(2),
        o.paymentMethod, o.createdByName || '', (o.discountTotal || 0).toFixed(2), o.total.toFixed(2)]);
    }
  }
  const csv = rows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')).join('\n');
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'minepos-report.csv';
  a.click();
}

// ── Shop settings ────────────────────────────────────────────────────────
async function loadShop() {
  try {
    const s = await api('GET', '/shop');
    document.getElementById('shopNameField').value = s.shopName || '';
    document.getElementById('shopAddress').value = s.address || '';
    document.getElementById('shopTaxId').value = s.taxId || '';
    document.getElementById('shopEmail').value = s.email || '';
    document.getElementById('shopReceiptFooter').value = s.receiptFooter || '';
    document.getElementById('shopPromptPayId').value = s.promptPayId || '';
    document.getElementById('shopPromptPayLabel').value = s.promptPayLabel || '';
  } catch (e) {}
}
async function saveShop() {
  const msg = document.getElementById('shopFormMsg');
  const shopName = document.getElementById('shopNameField').value.trim();
  if (!shopName) { msg.textContent = 'Shop name is required.'; msg.className = 'msg err'; return; }
  try {
    await api('PATCH', '/shop', {
      shopName,
      address: document.getElementById('shopAddress').value.trim() || null,
      taxId: document.getElementById('shopTaxId').value.trim() || null,
      email: document.getElementById('shopEmail').value.trim() || null,
      receiptFooter: document.getElementById('shopReceiptFooter').value.trim() || null,
      promptPayId: document.getElementById('shopPromptPayId').value.trim() || null,
      promptPayLabel: document.getElementById('shopPromptPayLabel').value.trim() || null,
    });
    msg.textContent = 'Saved.'; msg.className = 'msg ok';
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

// ── Advertising ──────────────────────────────────────────────────────────
let adSlides = [];
async function loadAds() {
  try { adSlides = await api('GET', '/ads'); } catch (e) { adSlides = []; }
  renderAdsList();
}
function renderAdsList() {
  const el = document.getElementById('adsList');
  el.innerHTML = adSlides.map((s, i) => `
    <div class="row" style="padding:8px 0; border-bottom:1px solid #262a35;">
      <div class="row" style="gap:10px;">
        <div style="display:flex;flex-direction:column;gap:2px;">
          <button class="small" ${i === 0 ? 'disabled' : ''} onclick="moveAdSlide(${i}, -1)">▲</button>
          <button class="small" ${i === adSlides.length - 1 ? 'disabled' : ''} onclick="moveAdSlide(${i}, 1)">▼</button>
        </div>
        ${s.type === 'video'
          ? `<div class="thumb thumb-clickable" style="display:flex;align-items:center;justify-content:center;" onclick="openMediaPreview('${s.url}', 'video', ${!!s.muted})">▶</div>`
          : `<img class="thumb thumb-clickable" src="${s.url}" onclick="openMediaPreview('${s.url}', 'image', false)">`}
        <span>${s.type === 'video' ? 'Video — plays until it ends' : (s.durationSeconds || 8) + 's'}</span>
        ${s.type === 'video'
          ? `<button class="small secondary" onclick="toggleAdMuted('${s.id}', ${!!s.muted})">${s.muted ? '\u{1F507} Muted' : '\u{1F50A} Sound on'}</button>`
          : ''}
      </div>
      <div>
        <button class="small secondary" onclick="openMediaPreview('${s.url}', '${s.type}', ${!!s.muted})">Preview</button>
        <button class="small danger" onclick="deleteAdSlide('${s.id}')">Delete</button>
      </div>
    </div>
  `).join('') || '<p class="sub">No slides yet.</p>';
}
async function toggleAdMuted(id, currentlyMuted) {
  try { await api('PATCH', '/ads/' + id, { muted: !currentlyMuted }); loadAds(); } catch (e) { alert(e.message); }
}
function openMediaPreview(url, type, muted) {
  const content = document.getElementById('mediaPreviewContent');
  content.innerHTML = type === 'video'
    ? `<video src="${url}" controls autoplay ${muted ? 'muted' : ''} style="max-width:88vw;max-height:82vh;"></video>`
    : `<img src="${url}" style="max-width:88vw;max-height:82vh;object-fit:contain;">`;
  document.getElementById('mediaPreviewOverlay').classList.remove('hidden');
}
function closeMediaPreview() {
  document.getElementById('mediaPreviewOverlay').classList.add('hidden');
  document.getElementById('mediaPreviewContent').innerHTML = '';
}
async function moveAdSlide(index, delta) {
  const target = index + delta;
  if (target < 0 || target >= adSlides.length) return;
  const reordered = adSlides.slice();
  const [moved] = reordered.splice(index, 1);
  reordered.splice(target, 0, moved);
  adSlides = reordered;
  renderAdsList();
  try { await api('POST', '/ads/reorder', { order: adSlides.map(s => s.id) }); } catch (e) { alert(e.message); loadAds(); }
}
function uploadAdSlide() {
  const msg = document.getElementById('adsMsg');
  const bar = document.getElementById('adsProgressBar');
  const barWrap = document.getElementById('adsProgressWrap');
  const file = document.getElementById('adsFile').files[0];
  if (!file) { msg.textContent = 'Choose a file first.'; msg.className = 'msg err'; return; }
  const ext = file.name.split('.').pop().toLowerCase();
  const duration = parseInt(document.getElementById('adsDuration').value, 10) || 8;

  msg.textContent = ''; msg.className = 'msg';
  barWrap.classList.remove('hidden');
  bar.style.width = '0%';

  // XMLHttpRequest (not fetch) specifically for upload.onprogress — fetch
  // has no cross-browser-reliable upload progress event.
  const xhr = new XMLHttpRequest();
  xhr.open('POST', `/ads?ext=${encodeURIComponent(ext)}&durationSeconds=${duration}`);
  xhr.setRequestHeader('Authorization', authHeaders()['Authorization']);
  xhr.setRequestHeader('Content-Type', 'application/octet-stream');
  xhr.upload.onprogress = (e) => {
    if (e.lengthComputable) bar.style.width = Math.round((e.loaded / e.total) * 100) + '%';
  };
  xhr.onload = () => {
    barWrap.classList.add('hidden');
    let data = {};
    try { data = JSON.parse(xhr.responseText); } catch (_) {}
    if (xhr.status < 200 || xhr.status >= 300) {
      msg.textContent = data.error || 'Upload failed.'; msg.className = 'msg err'; return;
    }
    document.getElementById('adsFile').value = '';
    msg.textContent = 'Uploaded.'; msg.className = 'msg ok';
    loadAds();
  };
  xhr.onerror = () => {
    barWrap.classList.add('hidden');
    msg.textContent = 'Could not reach the server.'; msg.className = 'msg err';
  };
  xhr.send(file);
}
async function deleteAdSlide(id) {
  if (!confirm('Delete this slide?')) return;
  try { await api('DELETE', '/ads/' + id); loadAds(); } catch (e) { alert(e.message); }
}

// ── Boot ─────────────────────────────────────────────────────────────────
if (token && role === 'owner') {
  document.getElementById('whoami').textContent = '(signed in)';
  enterApp();
}
</script>
</body>
</html>
''';
