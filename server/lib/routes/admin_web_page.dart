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
    color-scheme: light;
    --bg: #f7f4ed;
    --sidebar-bg: #f7f4ed;
    --card: #ffffff; --card-2: #f0f0e1; --border: #e7e2d3; --border-soft: #ede9dc;
    --input: #f7f4ed; --text: #282828; --muted: #766d70; --muted-soft: #55494c;
    --accent: #8d8f46; --accent-2: #6f7138; --accent-cyan: #8d8f46; --accent-glow: rgba(141,143,70,.18);
    --danger: #9a3a29; --danger-soft: #9a3a29; --ok: #5c7a3d; --ok-soft: #5c7a3d;
    --radius: 10px; --radius-sm: 7px;
    --shadow: 0 1px 2px rgba(40,40,40,.05), 0 1px 8px rgba(40,40,40,.04);
  }
  * { box-sizing: border-box; }
  ::-webkit-scrollbar { width: 10px; height: 10px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb { background: var(--border); border-radius: 10px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--muted); }
  body {
    margin: 0; min-height: 100vh;
    background: var(--bg); color: var(--text);
    font: 14.5px/1.6 -apple-system, "Segoe UI", system-ui, Roboto, sans-serif;
    -webkit-font-smoothing: antialiased;
  }
  h1 { font-size: 22px; margin: 0 0 4px; font-weight: 700; letter-spacing: -.01em; }
  h2 { font-size: 12.5px; margin: 0 0 16px; color: var(--muted-soft); text-transform: uppercase; letter-spacing: .06em; font-weight: 700; }
  h3 { font-size: 13px; margin: 18px 0 8px; color: var(--muted-soft); font-weight: 700; }
  .sub { color: var(--muted); margin: 0 0 24px; }
  .page-head { margin-bottom: 22px; }
  .card {
    background: var(--card); border: 1px solid var(--border); border-radius: var(--radius);
    padding: 22px 24px; margin-bottom: 18px; max-width: 760px; box-shadow: var(--shadow);
  }
  .card-grid {
    display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 18px; max-width: 1080px;
  }
  .card-grid .card { max-width: none; margin-bottom: 0; }
  label { display: block; font-size: 12px; color: var(--muted); margin: 10px 0 4px; font-weight: 600; }
  input, select, textarea {
    width: 100%; padding: 10px 12px; border-radius: var(--radius-sm); border: 1px solid var(--border);
    background: var(--input); color: var(--text); font-size: 14px; font-family: inherit;
    transition: border-color .15s, box-shadow .15s;
  }
  input:focus, select:focus, textarea:focus {
    outline: none; border-color: var(--accent); box-shadow: 0 0 0 3px var(--accent-glow);
  }
  textarea { resize: vertical; min-height: 60px; }
  input[type=checkbox] { width: auto; }
  button {
    margin-top: 14px; padding: 10px 20px; border-radius: var(--radius-sm); border: 1px solid var(--accent);
    background: var(--accent);
    color: white; font-weight: 600; cursor: pointer; font-size: 13px;
    transition: background .15s, border-color .15s, transform .1s;
  }
  button:hover { background: var(--accent-2); border-color: var(--accent-2); }
  button:active { transform: translateY(1px); }
  button.danger { background: var(--card); border-color: var(--danger-soft); color: var(--danger); }
  button.danger:hover { background: var(--card-2); border-color: var(--danger); }
  button.secondary { background: var(--card); color: var(--text); border: 1px solid var(--border); }
  button.secondary:hover { border-color: var(--accent); background: var(--card-2); }
  button.small { padding: 7px 12px; font-size: 12px; margin-top: 0; }
  button:disabled { opacity: .4; cursor: default; }
  .dot {
    display: inline-block; width: 9px; height: 9px; border-radius: 50%; margin-right: 6px;
    background: #9aa0ab;
  }
  .dot.live { background: var(--ok); }
  .dot.off { background: var(--danger); }
  .row { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
  .msg { font-size: 12px; margin-top: 8px; }
  .msg.err { color: var(--danger-soft); }
  .msg.ok { color: var(--ok-soft); }
  ul { list-style: none; padding: 0; margin: 0; }
  li { padding: 9px 0; border-bottom: 1px solid var(--border-soft); font-size: 13px; }
  li:last-child { border-bottom: none; }
  .role { color: var(--muted); font-size: 11px; text-transform: uppercase; }
  pre {
    background: var(--card-2); border: 1px solid var(--border); border-radius: var(--radius-sm); padding: 12px;
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
    width: 232px; flex: none; background: var(--sidebar-bg);
    padding: 18px 12px; display: flex; flex-direction: column;
  }
  .sidebar .brand { padding: 4px 8px 6px; display: flex; align-items: center; gap: 10px; }
  .sidebar .brand-name { font-weight: 600; font-size: 15px; letter-spacing: -.01em; line-height: 1.2; }
  .sidebar .brand-sub { font-size: 10px; color: var(--muted); letter-spacing: .04em; text-transform: uppercase; }
  .sidebar-divider { height: 1px; background: var(--border); margin: 12px 4px 14px; flex: none; }
  .nav-group { display: flex; flex-direction: column; gap: 2px; }
  .navbtn {
    display: flex; align-items: center; width: 100%; text-align: left; background: none; border: none;
    color: var(--muted); padding: 11px 12px; font-size: 13.5px; font-weight: 500;
    cursor: pointer; border-radius: var(--radius-sm); transition: background .15s, color .15s;
  }
  .navbtn:hover { background: var(--card-2); color: var(--text); }
  .navbtn.active { background: var(--card-2); color: var(--accent-2); font-weight: 600; }
  .navbtn .sub-nav-icon { margin-right: 10px; font-size: 14px; opacity: .8; }
  .sidebar-footer { margin-top: auto; padding-top: 14px; }
  main { flex: 1; padding: 32px 36px; overflow-y: auto; min-width: 0; }
  section { display: none; }
  section.active { display: block; }

  /* ── Tables / lists ────────────────────────────────────────────────── */
  .table-wrap {
    overflow-x: auto; border: 1px solid var(--border); border-radius: var(--radius-sm);
    margin-top: 14px; background: var(--card);
  }
  table { width: 100%; border-collapse: collapse; font-size: 13.5px; min-width: 480px; }
  th { text-align: left; color: var(--muted); font-size: 11px; text-transform: uppercase; letter-spacing: .04em;
       padding: 11px 14px; border-bottom: 1px solid var(--border); white-space: nowrap; }
  td { padding: 11px 14px; border-bottom: 1px solid var(--border-soft); vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tbody tr:hover { background: var(--card-2); }
  .chip {
    display: inline-flex; align-items: center; padding: 6px 14px; border-radius: 20px;
    border: 1px solid var(--border); background: var(--card); color: var(--muted); font-size: 12px; font-weight: 600;
    cursor: pointer; margin: 0 6px 6px 0; user-select: none; transition: all .12s;
  }
  .chip:hover { border-color: var(--accent); color: var(--text); }
  .chip.sel { background: var(--accent); border-color: var(--accent); color: white; }
  .chip.dim { opacity: .5; }
  .badge {
    display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 10px;
    font-weight: 700; letter-spacing: .03em; text-transform: uppercase; background: var(--card-2); color: var(--muted-soft);
  }
  .stat-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr)); gap: 14px; margin-bottom: 18px; }
  .stat-card {
    background: var(--card); border: 1px solid var(--border);
    border-radius: var(--radius); padding: 16px 18px; box-shadow: var(--shadow);
  }
  .stat-card .v { font-size: 21px; font-weight: 700; }
  .stat-card .l { font-size: 11px; color: var(--muted); margin-top: 4px; }
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
    max-height: 220px; overflow-y: auto; border: 1px solid var(--border); border-radius: 6px; padding: 8px 12px;
    background: var(--card);
  }
  .item-checklist label { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--text); margin: 7px 0; font-weight: 400; }
  .item-checklist input { width: auto; }
  .thumb { width: 44px; height: 44px; border-radius: 6px; object-fit: cover; background: var(--card-2); }
  .thumb-clickable { cursor: pointer; transition: transform .12s, box-shadow .12s; }
  .thumb-clickable:hover { box-shadow: 0 0 0 2px var(--accent); }
  .hidden { display: none !important; }

  /* ── Media preview lightbox ───────────────────────────────────────────── */
  .media-preview-overlay {
    position: fixed; inset: 0; z-index: 1000; background: rgba(20,22,26,.85);
    display: flex; align-items: center; justify-content: center;
  }
  .media-preview-close {
    position: absolute; top: 20px; right: 24px; margin: 0; padding: 8px 12px;
    background: var(--card-2); border: 1px solid var(--border); color: var(--text);
  }

  /* ── Upload progress ──────────────────────────────────────────────────── */
  .progress-wrap {
    margin-top: 10px; height: 8px; border-radius: 4px; background: var(--card-2);
    border: 1px solid var(--border); overflow: hidden;
  }
  .progress-bar {
    height: 100%; width: 0%; background: var(--accent);
    transition: width .15s ease;
  }

  /* ── Login ─────────────────────────────────────────────────────────── */
  #login, #createShop { min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
  .login-card { width: 100%; max-width: 340px; text-align: center; }
  .login-logo {
    width: 52px; height: 52px; margin: 0 auto 18px; border-radius: 8px;
    background: var(--accent);
    display: flex; align-items: center; justify-content: center;
    font-weight: 700; font-size: 22px; color: white;
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
      transform: translateX(-100%); transition: transform .22s ease; box-shadow: 4px 0 16px rgba(0,0,0,.15);
    }
    .sidebar.open { transform: translateX(0); }
    .sidebar-backdrop.open {
      display: block; position: fixed; inset: 0; background: rgba(20,22,26,.4); z-index: 240;
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

<div id="login" style="display:none;">
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

<div id="createShop" style="display:none;">
  <div class="card login-card">
    <div class="login-logo">M</div>
    <h2>Set Up Your Shop</h2>
    <p class="sub" style="margin-bottom:12px;">This server has no shop set up yet.</p>
    <div class="row" style="justify-content:center; gap:8px; margin-bottom:16px;">
      <button id="setupModeNewBtn" class="small" onclick="setSetupMode('new')">Create New</button>
      <button id="setupModeRestoreBtn" class="small secondary" onclick="setSetupMode('restore')">Import Backup</button>
    </div>

    <div id="setupNewPane">
      <label>Shop name</label>
      <input id="setupShopName">
      <label>Owner username</label>
      <input id="setupUsername" autocomplete="username">
      <label>Owner password</label>
      <input id="setupPassword" type="password" autocomplete="new-password">
      <button id="createShopBtn" onclick="doCreateShop()">Create Shop</button>
      <div id="createShopMsg" class="msg"></div>
    </div>

    <div id="setupRestorePane" class="hidden">
      <p class="sub" style="text-align:left; margin-bottom:12px;">
        Import a previously exported MinePOS backup (.db file) — this becomes this server's shop, accounts, menu and order history included.
      </p>
      <label>Backup file (.db)</label>
      <input type="file" id="restoreFileInput" accept=".db">
      <button id="restoreBtn" onclick="doRestoreBackup()">Import &amp; Restore</button>
      <div id="restoreMsg" class="msg"></div>
    </div>
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
            <div>
              <button class="secondary" onclick="openCategoryManager()">Manage Categories</button>
              <button onclick="openMenuForm(null)">Add Item</button>
            </div>
          </div>
          <div class="table-wrap">
            <table>
              <thead><tr><th></th><th>Name</th><th>Category</th><th>Price</th><th>Available</th><th></th></tr></thead>
              <tbody id="menuTableBody"></tbody>
            </table>
          </div>
        </div>

        <div id="categoryManagerCard" class="card hidden" style="max-width:960px;">
          <h3>Categories</h3>
          <p class="sub">Reorder how categories appear across the app, or rename one (relabels every item in it).</p>
          <div id="categoryManagerList"></div>
          <div class="row" style="margin-top:14px;"><button class="secondary" onclick="closeCategoryManager()">Close</button></div>
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
          <input id="menuImageFile" type="file" accept="image/*" onchange="onMenuImageSelected(this)">
          <div id="menuImagePreviewWrap" class="row hidden" style="gap:10px;margin-top:8px;">
            <img id="menuImagePreview" class="thumb" style="width:64px;height:64px;">
            <button type="button" class="small secondary" onclick="clearMenuImage()">Remove photo</button>
          </div>
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
              <thead><tr><th></th><th>Name</th><th>Username</th><th>Role</th><th>Active</th><th>Joined</th><th></th></tr></thead>
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
          <label>Photo (optional)</label>
          <input id="staffAvatarFile" type="file" accept="image/*" onchange="onStaffAvatarSelected(this)">
          <div id="staffAvatarPreviewWrap" class="row hidden" style="gap:10px;margin-top:8px;">
            <img id="staffAvatarPreview" class="thumb" style="width:64px;height:64px;border-radius:50%;">
            <button type="button" class="small secondary" onclick="clearStaffAvatar()">Remove photo</button>
          </div>
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
              <label>Categories (ctrl/cmd-click to select multiple)</label>
              <select id="promoScopeCategory" multiple></select>
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
          <h2>Sales Trend</h2>
          <canvas id="reportsTrendCanvas" style="width:100%;height:160px;display:block;"></canvas>
        </div>

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

        <div class="card">
          <h2>Backup</h2>
          <p class="sub">Download a full snapshot (accounts, menu, orders, shop settings) to restore later on this or another server.</p>
          <label style="display:block;margin-bottom:8px;font-weight:400;">
            <input type="checkbox" id="backupAdMedia"> Include ad images &amp; videos
          </label>
          <button class="secondary" onclick="exportBackup()">Export Backup</button>
          <div id="backupMsg" class="msg"></div>
        </div>

        <div class="card" style="border-color:var(--danger-soft);">
          <h2 style="color:var(--danger);">Danger Zone</h2>
          <p class="sub">Permanently deletes every account, menu item, and order on this server, and signs out every connected device. This cannot be undone.</p>
          <label>This shop's registered email</label>
          <input id="removeShopEmail">
          <label>Your username</label>
          <input id="removeShopUsername">
          <label>Your password</label>
          <input id="removeShopPassword" type="password">
          <button class="danger" onclick="removeShop()">DELETE SHOP</button>
          <div id="removeShopMsg" class="msg"></div>
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

        <div id="adEditCard" class="card hidden" style="max-width:760px;">
          <h3>Edit slide</h3>
          <label>Name (optional)</label>
          <input id="adEditName">
          <div id="adEditDurationWrap">
            <label>Seconds to show</label>
            <input id="adEditDuration" type="number" min="1" value="8">
          </div>
          <label>Transition</label>
          <select id="adEditTransition">
            <option value="none">None</option>
            <option value="fade">Fade</option>
            <option value="slideLeft">Slide left</option>
          </select>
          <label>Expiry</label>
          <select id="adEditExpiry" onchange="onAdEditExpiryChange()">
            <option value="never">Never</option>
            <option value="7">In 7 days</option>
            <option value="14">In 14 days</option>
            <option value="30">In 30 days</option>
            <option value="custom">Pick a date…</option>
          </select>
          <input id="adEditExpiryDate" type="date" class="hidden">
          <div class="row" style="margin-top:14px;">
            <button onclick="saveAdEdit()">Save</button>
            <button class="secondary" onclick="closeAdEdit()">Cancel</button>
          </div>
          <div id="adEditMsg" class="msg"></div>
        </div>
      </section>

    </main>
  </div>
</div>

<div id="mediaPreviewOverlay" class="media-preview-overlay hidden" onclick="if (event.target === this) closeMediaPreview()">
  <button class="media-preview-close" onclick="closeMediaPreview()">✕</button>
  <div id="mediaPreviewContent"></div>
</div>

<div id="cropOverlay" class="media-preview-overlay hidden">
  <div class="card" style="max-width:340px;text-align:center;">
    <h3 style="margin-top:0;">Crop Image</h3>
    <div style="position:relative;width:280px;height:280px;margin:0 auto;background:#000;">
      <canvas id="cropCanvas" width="280" height="280" style="display:block;cursor:grab;touch-action:none;"></canvas>
      <canvas id="cropGuideCanvas" width="280" height="280" style="position:absolute;top:0;left:0;pointer-events:none;"></canvas>
    </div>
    <div class="row" style="justify-content:center;gap:6px;margin-top:12px;">
      <button type="button" class="small secondary" onclick="cropZoom(0.83)">−</button>
      <button type="button" class="small secondary" onclick="cropZoom(1.2)">+</button>
      <button type="button" class="small secondary" onclick="cropRotate()">⟳ Rotate</button>
      <button type="button" class="small secondary" onclick="cropFlip('h')">⇋ Flip H</button>
      <button type="button" class="small secondary" onclick="cropFlip('v')">⇕ Flip V</button>
      <button type="button" class="small secondary" onclick="cropReset()">↺ Reset</button>
    </div>
    <p class="sub" style="margin-top:10px;">Drag to reposition • Scroll to zoom</p>
    <div class="row" style="justify-content:center;gap:8px;margin-top:6px;">
      <button type="button" onclick="cropConfirm()">Use Photo</button>
      <button type="button" class="secondary" onclick="cropCancel()">Cancel</button>
    </div>
  </div>
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
  if (name === 'menu') loadMenu().then(loadCategories);
  if (name === 'staff') loadStaff();
  // Promotions' scope pickers (item checklist, category dropdown) need
  // `menuItems` loaded regardless of whether the Menu section was visited
  // first this session.
  if (name === 'promotions') loadMenu().then(loadPromotions);
  if (name === 'reports') loadReports();
  if (name === 'shop') { loadShop(); document.getElementById('removeShopUsername').value = currentUsername; }
  if (name === 'ads') loadAds();
}

let currentUsername = '';
function enterApp() {
  document.getElementById('login').style.display = 'none';
  document.getElementById('app').style.display = 'block';
  loadConfig(); loadLogs(); poll(); loadMe();
  pollTimer = setInterval(poll, 5000);
}
async function loadMe() {
  try {
    const me = await api('GET', '/auth/me');
    currentUsername = me.username;
    document.getElementById('whoami').textContent = me.username + ' (owner)';
  } catch (e) {}
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
function chip(container, value, label, selected, onClick) {
  const el = document.createElement('div');
  el.className = 'chip' + (selected ? ' sel' : '');
  el.textContent = label;
  el.onclick = () => onClick(value);
  container.appendChild(el);
}

// ── Image crop (shared by Menu item photos and Staff avatars) ─────────────
// Canvas-based pan/zoom/rotate/flip crop into a fixed-square PNG, mirroring
// the Flutter app's pinch/pan-to-crop screen so both surfaces behave the
// same way. `cropOpen(file, circle)` resolves to a base64 PNG string (no
// data: prefix) once the user confirms, or null if they cancel.
const CROP_STAGE = 280;
const CROP_OUTPUT = 320;
let cropImg = null;
let cropResolve = null;
let cropTransform = { x: 0, y: 0, scale: 1, rotation: 0, flipH: false, flipV: false };

function cropOpen(file, circle) {
  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = () => {
      const img = new Image();
      img.onload = () => {
        cropImg = img;
        cropResolve = resolve;
        cropTransform = { x: 0, y: 0, scale: 1, rotation: 0, flipH: false, flipV: false };
        cropResetTransformToCover();
        drawCropGuide(circle);
        drawCrop();
        document.getElementById('cropOverlay').classList.remove('hidden');
      };
      img.onerror = () => resolve(null);
      img.src = reader.result;
    };
    reader.onerror = () => resolve(null);
    reader.readAsDataURL(file);
  });
}
function cropBoxDims() {
  const swap = cropTransform.rotation % 180 !== 0;
  const w = cropImg.width * cropTransform.scale, h = cropImg.height * cropTransform.scale;
  return swap ? { w: h, h: w } : { w, h };
}
// Fits the image's shorter side to the stage (cover-style) and centers it —
// called on open and after every rotate, so rotating always gives a
// predictable, fully-visible starting point instead of preserving whatever
// pan/zoom the previous orientation had.
function cropResetTransformToCover() {
  const swap = cropTransform.rotation % 180 !== 0;
  const w = swap ? cropImg.height : cropImg.width;
  const h = swap ? cropImg.width : cropImg.height;
  const scale = CROP_STAGE / Math.min(w, h);
  cropTransform.scale = scale;
  cropTransform.x = (CROP_STAGE - w * scale) / 2;
  cropTransform.y = (CROP_STAGE - h * scale) / 2;
}
function cropReset() { cropResetTransformToCover(); drawCrop(); }
function cropRotate() {
  cropTransform.rotation = (cropTransform.rotation + 90) % 360;
  cropResetTransformToCover();
  drawCrop();
}
function cropFlip(axis) {
  if (axis === 'h') cropTransform.flipH = !cropTransform.flipH;
  else cropTransform.flipV = !cropTransform.flipV;
  drawCrop();
}
function cropZoom(factor) {
  const before = cropBoxDims();
  const cx = cropTransform.x + before.w / 2, cy = cropTransform.y + before.h / 2;
  cropTransform.scale = Math.max(0.05, Math.min(8, cropTransform.scale * factor));
  const after = cropBoxDims();
  cropTransform.x = cx - after.w / 2;
  cropTransform.y = cy - after.h / 2;
  drawCrop();
}
// Draws the current transform into a `size`×`size` canvas — used for both
// the live preview (size = CROP_STAGE) and the final export (size =
// CROP_OUTPUT), so the exported crop always matches what was previewed.
function cropDrawInto(ctx, size) {
  const k = size / CROP_STAGE;
  const t = cropTransform;
  ctx.clearRect(0, 0, size, size);
  ctx.save();
  ctx.translate(t.x * k, t.y * k);
  const swap = t.rotation % 180 !== 0;
  const w = cropImg.width * t.scale * k, h = cropImg.height * t.scale * k;
  ctx.translate((swap ? h : w) / 2, (swap ? w : h) / 2);
  ctx.rotate(t.rotation * Math.PI / 180);
  ctx.scale((t.flipH ? -1 : 1) * t.scale * k, (t.flipV ? -1 : 1) * t.scale * k);
  ctx.drawImage(cropImg, -cropImg.width / 2, -cropImg.height / 2, cropImg.width, cropImg.height);
  ctx.restore();
}
function drawCrop() { cropDrawInto(document.getElementById('cropCanvas').getContext('2d'), CROP_STAGE); }
// Dims the four corners outside the inscribed circle for avatar crops
// (mirrors the app's circular guide), or a rule-of-thirds grid for menu
// items — drawn on a separate canvas so it never ends up baked into the
// exported PNG.
function drawCropGuide(circle) {
  const ctx = document.getElementById('cropGuideCanvas').getContext('2d');
  ctx.clearRect(0, 0, CROP_STAGE, CROP_STAGE);
  if (circle) {
    ctx.save();
    ctx.beginPath();
    ctx.rect(0, 0, CROP_STAGE, CROP_STAGE);
    ctx.arc(CROP_STAGE / 2, CROP_STAGE / 2, CROP_STAGE / 2, 0, Math.PI * 2, true);
    ctx.fillStyle = 'rgba(0,0,0,.5)';
    ctx.fill('evenodd');
    ctx.beginPath();
    ctx.arc(CROP_STAGE / 2, CROP_STAGE / 2, CROP_STAGE / 2, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255,255,255,.6)';
    ctx.stroke();
    ctx.restore();
  } else {
    ctx.strokeStyle = 'rgba(255,255,255,.4)';
    ctx.beginPath();
    for (const f of [1 / 3, 2 / 3]) {
      ctx.moveTo(CROP_STAGE * f, 0); ctx.lineTo(CROP_STAGE * f, CROP_STAGE);
      ctx.moveTo(0, CROP_STAGE * f); ctx.lineTo(CROP_STAGE, CROP_STAGE * f);
    }
    ctx.stroke();
  }
}
function cropCloseOverlay() {
  document.getElementById('cropOverlay').classList.add('hidden');
  cropImg = null; cropResolve = null;
}
function cropConfirm() {
  const out = document.createElement('canvas');
  out.width = CROP_OUTPUT; out.height = CROP_OUTPUT;
  cropDrawInto(out.getContext('2d'), CROP_OUTPUT);
  const dataUrl = out.toDataURL('image/png');
  const resolve = cropResolve;
  cropCloseOverlay();
  if (resolve) resolve(dataUrl.split(',')[1]);
}
function cropCancel() {
  const resolve = cropResolve;
  cropCloseOverlay();
  if (resolve) resolve(null);
}
function initCropHandlers() {
  const canvas = document.getElementById('cropCanvas');
  let dragging = false, start = null;
  const beginDrag = (x, y) => { dragging = true; start = { x, y, tx: cropTransform.x, ty: cropTransform.y }; };
  const moveDrag = (x, y) => {
    if (!dragging) return;
    cropTransform.x = start.tx + (x - start.x);
    cropTransform.y = start.ty + (y - start.y);
    drawCrop();
  };
  const endDrag = () => { dragging = false; };
  canvas.addEventListener('mousedown', (e) => beginDrag(e.clientX, e.clientY));
  window.addEventListener('mousemove', (e) => moveDrag(e.clientX, e.clientY));
  window.addEventListener('mouseup', endDrag);
  canvas.addEventListener('touchstart', (e) => { const t = e.touches[0]; beginDrag(t.clientX, t.clientY); }, { passive: true });
  canvas.addEventListener('touchmove', (e) => { const t = e.touches[0]; moveDrag(t.clientX, t.clientY); e.preventDefault(); }, { passive: false });
  canvas.addEventListener('touchend', endDrag);
  canvas.addEventListener('wheel', (e) => { e.preventDefault(); cropZoom(e.deltaY > 0 ? 0.83 : 1.2); }, { passive: false });
}

// ── Menu ─────────────────────────────────────────────────────────────────
let menuItems = [];
let menuCategoryFilter = 'All';
let menuEditingId = null;
let menuPendingImageBase64; // undefined = unchanged, null = removed, string = new crop

async function loadMenu() {
  try { menuItems = await api('GET', '/menu'); } catch (e) { menuItems = []; }
  renderMenuCategoryChips();
  renderMenuTable();
}

function renderMenuCategoryChips() {
  const used = [...new Set(menuItems.map(i => i.category))];
  const ordered = categoryOrder.length
    ? [...categoryOrder.filter(c => used.includes(c)), ...used.filter(c => !categoryOrder.includes(c))]
    : used;
  const cats = ['All', ...ordered];
  const container = document.getElementById('menuCategoryChips');
  container.innerHTML = '';
  for (const c of cats) chip(container, c, c, c === menuCategoryFilter, (v) => { menuCategoryFilter = v; renderMenuTable(); });
  const datalist = document.getElementById('menuCategoryList');
  datalist.innerHTML = cats.filter(c => c !== 'All').map(c => `<option value="${esc(c)}">`).join('');
}

// ── Menu categories (rename + reorder) ──────────────────────────────────
// The saved order (PUT /menu/categories/order) may list categories no item
// uses anymore, or be missing ones a user just free-typed onto an item — so
// it's merged against what's actually in use every time it's loaded.
let categoryOrder = [];
async function loadCategories() {
  let saved = [];
  try { saved = (await api('GET', '/menu/categories/order')).order || []; } catch (e) {}
  const used = [...new Set(menuItems.map(i => i.category))];
  categoryOrder = [...saved.filter(c => used.includes(c)), ...used.filter(c => !saved.includes(c))];
  renderMenuCategoryChips();
  renderCategoriesList();
}
function openCategoryManager() {
  renderCategoriesList();
  document.getElementById('categoryManagerCard').classList.remove('hidden');
}
function closeCategoryManager() { document.getElementById('categoryManagerCard').classList.add('hidden'); }
function renderCategoriesList() {
  const el = document.getElementById('categoryManagerList');
  el.innerHTML = categoryOrder.map((c, i) => `
    <div class="row" style="padding:8px 0; border-bottom:1px solid var(--border-soft);">
      <div class="row" style="gap:10px;">
        <div style="display:flex;flex-direction:column;gap:2px;">
          <button class="small" ${i === 0 ? 'disabled' : ''} onclick="moveCategory(${i}, -1)">▲</button>
          <button class="small" ${i === categoryOrder.length - 1 ? 'disabled' : ''} onclick="moveCategory(${i}, 1)">▼</button>
        </div>
        <span>${esc(c)}</span>
      </div>
      <button class="small secondary" onclick="renameCategoryAt(${i})">Rename</button>
    </div>
  `).join('') || '<p class="sub">No categories yet.</p>';
}
async function moveCategory(index, delta) {
  const target = index + delta;
  if (target < 0 || target >= categoryOrder.length) return;
  const reordered = categoryOrder.slice();
  const [moved] = reordered.splice(index, 1);
  reordered.splice(target, 0, moved);
  categoryOrder = reordered;
  renderCategoriesList();
  renderMenuCategoryChips();
  try { await api('PUT', '/menu/categories/order', { order: categoryOrder }); } catch (e) { alert(e.message); loadCategories(); }
}
function renameCategoryAt(i) {
  const from = categoryOrder[i];
  const to = prompt('Rename "' + from + '" to:', from);
  if (!to || !to.trim() || to.trim() === from) return;
  renameCategory(from, to.trim());
}
async function renameCategory(from, to) {
  try {
    await api('PUT', '/menu/categories/rename', { from, to });
    await loadMenu();
    await loadCategories();
  } catch (e) { alert(e.message); }
}

async function onMenuImageSelected(input) {
  const file = input.files[0];
  input.value = '';
  if (!file) return;
  const cropped = await cropOpen(file, false);
  if (!cropped) return;
  menuPendingImageBase64 = cropped;
  showMenuImagePreview(cropped);
}
function showMenuImagePreview(base64) {
  const wrap = document.getElementById('menuImagePreviewWrap');
  if (!base64) { wrap.classList.add('hidden'); return; }
  document.getElementById('menuImagePreview').src = 'data:image/png;base64,' + base64;
  wrap.classList.remove('hidden');
}
function clearMenuImage() { menuPendingImageBase64 = null; showMenuImagePreview(null); }

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
  menuPendingImageBase64 = undefined;
  showMenuImagePreview(item ? item.imageBase64 : null);
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
  const existing = menuEditingId ? menuItems.find(i => i.id === menuEditingId) : null;
  const body = {
    name, category, price,
    available: document.getElementById('menuAvailable').checked,
    hasSweetness: document.getElementById('menuHasSweetness').checked,
    nameTh: document.getElementById('menuNameTh').value.trim() || null,
    imageBase64: menuPendingImageBase64 !== undefined ? menuPendingImageBase64 : (existing ? existing.imageBase64 : null),
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
let staffPendingAvatarBase64; // undefined = unchanged, null = removed, string = new crop

async function loadStaff() {
  try { staffList = await api('GET', '/users'); } catch (e) { staffList = []; }
  renderStaffTable();
}

function renderStaffTable() {
  const body = document.getElementById('staffTableBody');
  body.innerHTML = staffList.map(u => `
    <tr>
      <td>${u.avatarBase64 ? `<img class="thumb" style="border-radius:50%;" src="data:image/png;base64,${u.avatarBase64}">` : ''}</td>
      <td>${esc(u.name || u.username)}</td>
      <td>@${esc(u.username)}</td>
      <td><span class="badge">${esc(u.role)}</span></td>
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
  document.getElementById('staffAvatarFile').value = '';
  staffPendingAvatarBase64 = undefined;
  showStaffAvatarPreview(u ? u.avatarBase64 : null);
  document.getElementById('staffActiveWrap').classList.toggle('hidden', !u);
  document.getElementById('staffActive').checked = u ? u.active : true;
  document.getElementById('staffRenameWrap').classList.toggle('hidden', !u);
  document.getElementById('staffNewUsername').value = '';
  document.getElementById('staffConfirmPassword').value = '';
  document.getElementById('staffFormMsg').textContent = '';
  document.getElementById('staffFormCard').classList.remove('hidden');
}
function closeStaffForm() { document.getElementById('staffFormCard').classList.add('hidden'); }

async function onStaffAvatarSelected(input) {
  const file = input.files[0];
  input.value = '';
  if (!file) return;
  const cropped = await cropOpen(file, true);
  if (!cropped) return;
  staffPendingAvatarBase64 = cropped;
  showStaffAvatarPreview(cropped);
}
function showStaffAvatarPreview(base64) {
  const wrap = document.getElementById('staffAvatarPreviewWrap');
  if (!base64) { wrap.classList.add('hidden'); return; }
  document.getElementById('staffAvatarPreview').src = 'data:image/png;base64,' + base64;
  wrap.classList.remove('hidden');
}
function clearStaffAvatar() { staffPendingAvatarBase64 = null; showStaffAvatarPreview(null); }

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
        avatarBase64: staffPendingAvatarBase64 || null,
      });
    } else {
      const existing = staffList.find(s => s.id === staffEditingId);
      const body = {
        role: document.getElementById('staffRole').value,
        active: document.getElementById('staffActive').checked,
        name: document.getElementById('staffName').value.trim() || null,
        email: document.getElementById('staffEmail').value.trim() || null,
        phone: document.getElementById('staffPhone').value.trim() || null,
        avatarBase64: staffPendingAvatarBase64 !== undefined ? staffPendingAvatarBase64 : (existing ? existing.avatarBase64 : null),
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
      <td>${esc(p.scopeType === 'category' ? ((p.scopeCategories || []).join(', ') || 'category') : p.scopeType)}</td>
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
    scopeItemIds: p.scopeItemIds, scopeCategories: p.scopeCategories, excludeItemIds: p.excludeItemIds,
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
        onchange="onItemCheckChange('${listId}', '${i.id}', this.checked)"> ${esc(i.name)} <span style="color:var(--muted);">(${esc(i.category)})</span></label>
    `).join('') || '<span class="sub">No menu items yet.</span>';
  }
  const catSel = document.getElementById('promoScopeCategory');
  const cats = [...new Set(menuItems.map(i => i.category))];
  const currentlySelected = new Set(Array.from(catSel.selectedOptions).map(o => o.value));
  catSel.innerHTML = cats.map(c => `<option value="${esc(c)}">${esc(c)}</option>`).join('');
  if (promoEditingId) {
    const p = promoList.find(x => x.id === promoEditingId);
    const wanted = new Set(p?.scopeCategories || []);
    for (const opt of catSel.options) opt.selected = wanted.has(opt.value);
  } else {
    for (const opt of catSel.options) opt.selected = currentlySelected.has(opt.value);
  }
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
    scopeCategories: !isCombo && promoScopeType === 'category'
      ? Array.from(document.getElementById('promoScopeCategory').selectedOptions).map(o => o.value)
      : [],
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

  renderReportsTrend(orders, start, end);

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

// Day-bucketed revenue line chart — mirrors the mobile app's Sales Trend
// graph (filled area under a rounded stroke, with a dot per day) using
// nothing but the canvas 2D API, no charting library.
function renderReportsTrend(orders, start, end) {
  const canvas = document.getElementById('reportsTrendCanvas');
  const dpr = window.devicePixelRatio || 1;
  const cssWidth = canvas.clientWidth || canvas.parentElement.clientWidth;
  const cssHeight = 160;
  canvas.width = cssWidth * dpr;
  canvas.height = cssHeight * dpr;
  const ctx = canvas.getContext('2d');
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.clearRect(0, 0, cssWidth, cssHeight);

  const dayMs = 24 * 60 * 60 * 1000;
  const startDay = new Date(start.getFullYear(), start.getMonth(), start.getDate());
  const dayCount = Math.max(1, Math.round((end - startDay) / dayMs));
  const buckets = new Array(dayCount).fill(0);
  for (const o of orders) {
    const idx = Math.floor((new Date(o.createdAt) - startDay) / dayMs);
    if (idx >= 0 && idx < dayCount) buckets[idx] += o.total;
  }
  const maxValue = Math.max(1, ...buckets);

  const padLeft = 44, padBottom = 18, padTop = 6;
  const plotWidth = cssWidth - padLeft - 8;
  const plotHeight = cssHeight - padBottom - padTop;

  ctx.strokeStyle = '#e5d9cf'; ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.moveTo(padLeft, padTop); ctx.lineTo(padLeft, padTop + plotHeight); ctx.lineTo(padLeft + plotWidth, padTop + plotHeight);
  ctx.stroke();

  ctx.fillStyle = '#8a7c6f'; ctx.font = '10px sans-serif'; ctx.textAlign = 'right';
  ctx.fillText(baht(maxValue), padLeft - 6, padTop + 8);
  ctx.fillText('฿0', padLeft - 6, padTop + plotHeight);

  const accent = (getComputedStyle(document.documentElement).getPropertyValue('--accent') || '#8d8f46').trim();
  const slot = plotWidth / dayCount;
  const points = buckets.map((v, i) => ({
    x: padLeft + slot * (i + 0.5),
    y: padTop + plotHeight - (v / maxValue) * plotHeight,
  }));

  // Filled area under the line, same 12%-alpha treatment as the app.
  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  for (const p of points.slice(1)) ctx.lineTo(p.x, p.y);
  ctx.lineTo(points[points.length - 1].x, padTop + plotHeight);
  ctx.lineTo(points[0].x, padTop + plotHeight);
  ctx.closePath();
  ctx.save();
  ctx.globalAlpha = 0.12;
  ctx.fillStyle = accent;
  ctx.fill();
  ctx.restore();

  // The line itself, plus a small dot at each day.
  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  for (const p of points.slice(1)) ctx.lineTo(p.x, p.y);
  ctx.strokeStyle = accent;
  ctx.lineWidth = 2.5;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.stroke();

  ctx.fillStyle = accent;
  for (const p of points) {
    ctx.beginPath();
    ctx.arc(p.x, p.y, 2.5, 0, Math.PI * 2);
    ctx.fill();
  }

  // At most ~6 date labels so they don't collide on a wide range.
  const labelEvery = Math.max(1, Math.ceil(dayCount / 6));
  ctx.fillStyle = '#8a7c6f'; ctx.textAlign = 'center';
  for (let i = 0; i < dayCount; i += labelEvery) {
    const d = new Date(startDay.getTime() + i * dayMs);
    ctx.fillText(`${d.getMonth() + 1}/${d.getDate()}`, points[i].x, cssHeight - 4);
  }
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

async function exportBackup() {
  const msg = document.getElementById('backupMsg');
  msg.textContent = ''; msg.className = 'msg';
  try {
    const withMedia = document.getElementById('backupAdMedia').checked;
    const res = await fetch('/admin/backup' + (withMedia ? '?includeAdMedia=true' : ''), { headers: authHeaders() });
    if (res.status === 401) { logout(); throw new Error('Signed out'); }
    if (!res.ok) {
      const data = await res.json().catch(() => null);
      throw new Error((data && data.error) || 'Backup failed.');
    }
    const disposition = res.headers.get('content-disposition') || '';
    const match = disposition.match(/filename="?([^"]+)"?/);
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = match ? match[1] : 'minepos-backup.db'; a.click();
    URL.revokeObjectURL(url);
    msg.textContent = 'Downloaded.'; msg.className = 'msg ok';
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

async function removeShop() {
  const msg = document.getElementById('removeShopMsg');
  const email = document.getElementById('removeShopEmail').value.trim();
  const username = document.getElementById('removeShopUsername').value.trim();
  const password = document.getElementById('removeShopPassword').value;
  if (!email || !username || !password) {
    msg.textContent = 'Email, username, and password are all required.'; msg.className = 'msg err'; return;
  }
  if (!confirm('This permanently deletes every account, menu item, and order on this server, and signs out every connected device. This cannot be undone. Continue?')) return;
  try {
    await api('DELETE', '/shop', { email, username, password });
    logout();
    location.reload();
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
    <div class="row" style="padding:8px 0; border-bottom:1px solid var(--border-soft);">
      <div class="row" style="gap:10px;">
        <div style="display:flex;flex-direction:column;gap:2px;">
          <button class="small" ${i === 0 ? 'disabled' : ''} onclick="moveAdSlide(${i}, -1)">▲</button>
          <button class="small" ${i === adSlides.length - 1 ? 'disabled' : ''} onclick="moveAdSlide(${i}, 1)">▼</button>
        </div>
        ${s.type === 'video'
          ? `<div class="thumb thumb-clickable" style="display:flex;align-items:center;justify-content:center;" onclick="openMediaPreview('${s.url}', 'video', ${!!s.muted})">▶</div>`
          : `<img class="thumb thumb-clickable" src="${s.url}" onclick="openMediaPreview('${s.url}', 'image', false)">`}
        <div style="display:flex;flex-direction:column;">
          <span>${esc(s.name) || '<span style="color:var(--muted);">(unnamed)</span>'}</span>
          <span class="sub">${s.type === 'video' ? 'Video — plays until it ends' : (s.durationSeconds || 8) + 's'}${s.expiresAt ? ' • expires ' + new Date(s.expiresAt).toLocaleDateString() : ''}</span>
        </div>
        ${s.type === 'video'
          ? `<button class="small secondary" onclick="toggleAdMuted('${s.id}', ${!!s.muted})">${s.muted ? '\u{1F507} Muted' : '\u{1F50A} Sound on'}</button>`
          : ''}
      </div>
      <div>
        <button class="small secondary" onclick="openMediaPreview('${s.url}', '${s.type}', ${!!s.muted})">Preview</button>
        <button class="small secondary" onclick="openAdEdit('${s.id}')">Edit</button>
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

let editingAdId = null;
function onAdEditExpiryChange() {
  const custom = document.getElementById('adEditExpiry').value === 'custom';
  document.getElementById('adEditExpiryDate').classList.toggle('hidden', !custom);
}
function openAdEdit(id) {
  const s = adSlides.find(x => x.id === id);
  if (!s) return;
  editingAdId = id;
  document.getElementById('adEditName').value = s.name || '';
  document.getElementById('adEditTransition').value = s.transition || 'fade';
  document.getElementById('adEditDurationWrap').classList.toggle('hidden', s.type === 'video');
  document.getElementById('adEditDuration').value = s.durationSeconds || 8;
  const expirySel = document.getElementById('adEditExpiry');
  const dateInput = document.getElementById('adEditExpiryDate');
  if (s.expiresAt) {
    expirySel.value = 'custom';
    dateInput.value = s.expiresAt.slice(0, 10);
  } else {
    expirySel.value = 'never';
    dateInput.value = '';
  }
  onAdEditExpiryChange();
  document.getElementById('adEditMsg').textContent = '';
  document.getElementById('adEditMsg').className = 'msg';
  document.getElementById('adEditCard').classList.remove('hidden');
  document.getElementById('adEditCard').scrollIntoView({ behavior: 'smooth', block: 'nearest' });
}
function closeAdEdit() {
  editingAdId = null;
  document.getElementById('adEditCard').classList.add('hidden');
}
async function saveAdEdit() {
  if (!editingAdId) return;
  const msg = document.getElementById('adEditMsg');
  const body = {
    name: document.getElementById('adEditName').value.trim(),
    transition: document.getElementById('adEditTransition').value,
  };
  if (!document.getElementById('adEditDurationWrap').classList.contains('hidden')) {
    body.durationSeconds = parseInt(document.getElementById('adEditDuration').value, 10) || 8;
  }
  const expiry = document.getElementById('adEditExpiry').value;
  if (expiry === 'never') {
    body.expiresAt = null;
  } else if (expiry === 'custom') {
    const dateVal = document.getElementById('adEditExpiryDate').value;
    body.expiresAt = dateVal ? new Date(dateVal).toISOString() : null;
  } else {
    body.expiresInDays = parseInt(expiry, 10);
  }
  try {
    await api('PATCH', '/ads/' + editingAdId, body);
    closeAdEdit();
    loadAds();
  } catch (e) { msg.textContent = e.message; msg.className = 'msg err'; }
}

// ── Boot ─────────────────────────────────────────────────────────────────
// A brand-new server has no shop (and so no owner account) to sign into at
// all — /health's `hasShop` is checked before deciding whether to show the
// normal sign-in form or the one-time Create Shop form instead.
async function boot() {
  initCropHandlers();
  let hasShop = true;
  try {
    const health = await (await fetch('/health')).json();
    hasShop = health.hasShop !== false;
  } catch (e) {
    // Can't reach the server at all — default to the sign-in form same as
    // before this check existed; doLogin()'s own "Could not reach the
    // server." message covers this case from there.
  }
  if (!hasShop) {
    document.getElementById('createShop').style.display = 'flex';
    return;
  }
  if (token && role === 'owner') {
    document.getElementById('whoami').textContent = '(signed in)';
    enterApp();
  } else {
    document.getElementById('login').style.display = 'flex';
  }
}
boot();

async function doCreateShop() {
  const shopName = document.getElementById('setupShopName').value.trim();
  const username = document.getElementById('setupUsername').value.trim();
  const password = document.getElementById('setupPassword').value;
  const msg = document.getElementById('createShopMsg');
  msg.textContent = ''; msg.className = 'msg';
  if (!shopName) { msg.textContent = 'Shop name is required.'; msg.className = 'msg err'; return; }
  if (!username) { msg.textContent = 'Owner username is required.'; msg.className = 'msg err'; return; }
  if (!password || password.length < 6) { msg.textContent = 'Password must be at least 6 characters.'; msg.className = 'msg err'; return; }
  try {
    const res = await fetch('/setup', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ shopName, adminUsername: username, adminPassword: password }),
    });
    const data = await res.json().catch(() => null);
    if (!res.ok) { msg.textContent = (data && data.error) || 'Could not create the shop.'; msg.className = 'msg err'; return; }
  } catch (e) {
    msg.textContent = 'Could not reach the server.'; msg.className = 'msg err'; return;
  }
  // Shop created — sign the new owner straight in rather than making them
  // retype the same credentials on a second screen.
  document.getElementById('createShop').style.display = 'none';
  document.getElementById('loginUser').value = username;
  document.getElementById('loginPass').value = password;
  document.getElementById('login').style.display = 'flex';
  await doLogin();
}

function setSetupMode(mode) {
  const isNew = mode === 'new';
  document.getElementById('setupNewPane').classList.toggle('hidden', !isNew);
  document.getElementById('setupRestorePane').classList.toggle('hidden', isNew);
  document.getElementById('setupModeNewBtn').className = isNew ? 'small' : 'small secondary';
  document.getElementById('setupModeRestoreBtn').className = isNew ? 'small secondary' : 'small';
}

// Imports a previously exported MinePOS backup (a raw .db file — see GET
// /admin/backup) as this server's shop. Only reachable from the no-shop-yet
// screen, matching /admin/restore's own "this server has no shop" gate —
// same one-time bootstrap as Create Shop, just seeded from a file instead of
// a blank slate.
async function doRestoreBackup() {
  const input = document.getElementById('restoreFileInput');
  const msg = document.getElementById('restoreMsg');
  const btn = document.getElementById('restoreBtn');
  msg.textContent = ''; msg.className = 'msg';
  const file = input.files && input.files[0];
  if (!file) { msg.textContent = 'Choose a backup file first.'; msg.className = 'msg err'; return; }

  btn.disabled = true;
  msg.textContent = 'Uploading…'; msg.className = 'msg';
  try {
    const bytes = await file.arrayBuffer();
    const res = await fetch('/admin/restore', {
      method: 'POST', headers: { 'Content-Type': 'application/octet-stream' }, body: bytes,
    });
    const data = await res.json().catch(() => null);
    if (!res.ok) {
      msg.textContent = (data && data.error) || 'Could not restore that backup.';
      msg.className = 'msg err'; btn.disabled = false; return;
    }
  } catch (e) {
    msg.textContent = 'Could not reach the server.'; msg.className = 'msg err'; btn.disabled = false; return;
  }

  // The server now closes and reopens itself with the restored database —
  // briefly unreachable while that happens, so poll /health until it's back
  // instead of assuming any fixed delay, then reload to a clean boot() with
  // the (now populated) shop.
  msg.textContent = 'Restored — reconnecting…'; msg.className = 'msg';
  let attempts = 0;
  const poll = setInterval(async () => {
    attempts++;
    try {
      const health = await (await fetch('/health')).json();
      if (health.hasShop) { clearInterval(poll); location.reload(); }
    } catch (e) {
      // Not back up yet — keep polling.
    }
    if (attempts >= 30) {
      clearInterval(poll);
      msg.textContent = 'Restore may have finished — refresh the page to check.';
      msg.className = 'msg err';
    }
  }, 1000);
}
</script>
</body>
</html>
''';
