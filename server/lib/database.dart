import 'dart:io';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';

const _uuid = Uuid();

// ── Domain models ─────────────────────────────────────────────────────────────

class DbUser {
  DbUser({
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.active,
    required this.tokenVersion,
    required this.createdAt,
  });

  final String username;
  final String passwordHash;
  final String role;
  final bool active;
  final int tokenVersion;
  final DateTime createdAt;

  factory DbUser._fromRow(Row row) => DbUser(
        username: row['username'] as String,
        passwordHash: row['password_hash'] as String,
        role: row['role'] as String,
        active: (row['active'] as int) == 1,
        tokenVersion: row['token_version'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'username': username,
        'role': role,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
      };
}

class DbOtp {
  DbOtp({required this.otp, required this.expiresAt});
  final String otp;
  final DateTime expiresAt;

  factory DbOtp._fromRow(Row row) => DbOtp(
        otp: row['otp'] as String,
        expiresAt: DateTime.parse(row['expires_at'] as String),
      );
}

class DbMenuItem {
  DbMenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.available,
    this.imageBase64,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final bool available;
  final String? imageBase64;

  factory DbMenuItem._fromRow(Row row) => DbMenuItem(
        id: row['id'] as String,
        name: row['name'] as String,
        category: row['category'] as String,
        price: (row['price'] as num).toDouble(),
        available: (row['available'] as int) == 1,
        imageBase64: row['image_base64'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'available': available,
        'imageBase64': imageBase64,
      };
}

class DbOrderItem {
  DbOrderItem({
    required this.id,
    required this.menuItemId,
    required this.menuItemName,
    required this.menuItemCategory,
    required this.price,
    required this.quantity,
    required this.status,
  });

  final int id;
  final String menuItemId;
  final String menuItemName;
  final String menuItemCategory;
  final double price;
  final int quantity;

  /// Per-item kitchen prep state: one of [kOrderItemStatuses]. Unlike the
  /// parent order's status, an item never reaches "completed" on its own —
  /// serving the whole order is an order-level action.
  final String status;

  factory DbOrderItem._fromRow(Row row) => DbOrderItem(
        id: row['id'] as int,
        menuItemId: row['menu_item_id'] as String,
        menuItemName: row['menu_item_name'] as String,
        menuItemCategory: row['menu_item_category'] as String,
        price: (row['price'] as num).toDouble(),
        quantity: row['quantity'] as int,
        status: row['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'menuItemId': menuItemId,
        'menuItemName': menuItemName,
        'menuItemCategory': menuItemCategory,
        'price': price,
        'quantity': quantity,
        'status': status,
      };

  double get subtotal => price * quantity;
}

/// Kitchen prep states an order moves through, oldest-first.
const kOrderStatuses = ['pending', 'preparing', 'ready', 'completed'];

/// Per-item prep states — a subset of [kOrderStatuses] with no "completed"
/// (serving is order-level only).
const kOrderItemStatuses = ['pending', 'preparing', 'ready'];

class DbOrder {
  DbOrder({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    required this.paymentMethod,
    required this.total,
    required this.items,
    required this.status,
    this.amountPaid,
  });

  final int id;
  final int orderNumber;
  final DateTime createdAt;
  final String paymentMethod;
  final double total;
  final double? amountPaid;
  final String status;
  final List<DbOrderItem> items;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'createdAt': createdAt.toIso8601String(),
        'paymentMethod': paymentMethod,
        'status': status,
        'total': total,
        'amountPaid': amountPaid,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

// ── AppDb ─────────────────────────────────────────────────────────────────────

class AppDb {
  AppDb._(this._db);

  static AppDb? _instance;
  static AppDb get instance => _instance!;

  final Database _db;

  static Future<AppDb> open(ServerConfig config) async {
    await Directory(config.dataDir).create(recursive: true);
    final dbPath = p.join(config.dataDir, 'minepos.db');
    final db = sqlite3.open(dbPath);
    final instance = AppDb._(db);
    instance._migrate();
    _instance = instance;

    // Seed admin user from env vars only if explicitly configured for
    // headless/scripted deployment — otherwise wait for POST /setup (the
    // Create Shop wizard) to bootstrap the first owner account for real.
    if (config.autoSeedAdmin && !instance.hasAnyUser()) {
      final pass = config.adminPass;
      instance.createUser(
        username: config.adminUser,
        password: pass,
        role: 'owner',
      );
      print('Created admin user "${config.adminUser}" with password: $pass');
      print('Change this password immediately in a production environment.');
    }

    // Seed default menu if empty.
    if (instance.getMenuItems().isEmpty) {
      instance._seedMenu();
    }

    return instance;
  }

  void _migrate() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        username TEXT PRIMARY KEY,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'worker',
        active INTEGER NOT NULL DEFAULT 1,
        token_version INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    // Backfill columns for databases created before these fields existed.
    final userCols =
        _db.select("PRAGMA table_info(users)").map((r) => r['name']).toSet();
    if (!userCols.contains('active')) {
      _db.execute(
          'ALTER TABLE users ADD COLUMN active INTEGER NOT NULL DEFAULT 1');
    }
    if (!userCols.contains('token_version')) {
      _db.execute(
          'ALTER TABLE users ADD COLUMN token_version INTEGER NOT NULL DEFAULT 0');
    }

    _db.execute('''
      CREATE TABLE IF NOT EXISTS otp_tokens (
        username TEXT PRIMARY KEY,
        otp TEXT NOT NULL,
        expires_at TEXT NOT NULL
      )
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS menu_items (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        available INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        image_base64 TEXT
      )
    ''');
    final menuCols = _db
        .select("PRAGMA table_info(menu_items)")
        .map((r) => r['name'])
        .toSet();
    if (!menuCols.contains('image_base64')) {
      _db.execute('ALTER TABLE menu_items ADD COLUMN image_base64 TEXT');
    }

    _db.execute('''
      CREATE TABLE IF NOT EXISTS orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        amount_paid REAL,
        total REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed'
      )
    ''');
    // Backfill for databases created before kitchen status tracking existed —
    // those orders already happened, so 'completed' is the correct default.
    // New orders always set status explicitly to 'pending' on insert.
    final orderCols = _db
        .select("PRAGMA table_info(orders)")
        .map((r) => r['name'])
        .toSet();
    if (!orderCols.contains('status')) {
      _db.execute(
          "ALTER TABLE orders ADD COLUMN status TEXT NOT NULL DEFAULT 'completed'");
    }

    _db.execute('''
      CREATE TABLE IF NOT EXISTS order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL REFERENCES orders(id),
        menu_item_id TEXT NOT NULL,
        menu_item_name TEXT NOT NULL,
        menu_item_category TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');
    // Backfill for databases created before item-level tracking existed.
    // Historical rows belong to orders that are already 'completed' (see
    // above), so 'pending' is just a harmless default — nothing reads item
    // status on a completed order.
    final itemCols = _db
        .select("PRAGMA table_info(order_items)")
        .map((r) => r['name'])
        .toSet();
    if (!itemCols.contains('status')) {
      _db.execute(
          "ALTER TABLE order_items ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'");
    }

    // Singleton row (id always 1) holding the shop's own details, set once
    // via POST /setup.
    _db.execute('''
      CREATE TABLE IF NOT EXISTS shop_config (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        shop_name TEXT NOT NULL,
        address TEXT,
        tax_id TEXT,
        email TEXT,
        receipt_footer TEXT
      )
    ''');
  }

  // ── Shop config ──────────────────────────────────────────────────────────────

  Map<String, dynamic>? getShopConfig() {
    final rows = _db.select('SELECT * FROM shop_config WHERE id = 1');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return {
      'shopName': row['shop_name'],
      'address': row['address'],
      'taxId': row['tax_id'],
      'email': row['email'],
      'receiptFooter': row['receipt_footer'],
    };
  }

  void setShopConfig({
    required String shopName,
    String? address,
    String? taxId,
    String? email,
    String? receiptFooter,
  }) {
    _db.execute(
      'INSERT OR REPLACE INTO shop_config '
      '(id, shop_name, address, tax_id, email, receipt_footer) '
      'VALUES (1, ?, ?, ?, ?, ?)',
      [shopName, address, taxId, email, receiptFooter],
    );
  }

  /// Wipes every row from every table — shop config, all accounts, menu,
  /// orders — resetting the server to the same pristine state as before
  /// POST /setup was ever called, so a new shop can be bootstrapped again.
  /// Existing JWTs for the deleted owner stop working immediately since
  /// [verifyToken] looks the user up by username on every request.
  void wipeShop() {
    _db.execute('DELETE FROM order_items');
    _db.execute('DELETE FROM orders');
    _db.execute('DELETE FROM menu_items');
    _db.execute('DELETE FROM otp_tokens');
    _db.execute('DELETE FROM users');
    _db.execute('DELETE FROM shop_config');
  }

  // ── User ───────────────────────────────────────────────────────────────────

  bool hasAnyUser() {
    final rows = _db.select('SELECT COUNT(*) AS c FROM users');
    return (rows.first['c'] as int) > 0;
  }

  DbUser? getUserByUsername(String username) {
    final rows = _db.select(
      'SELECT * FROM users WHERE username = ?',
      [username.toLowerCase()],
    );
    if (rows.isEmpty) return null;
    return DbUser._fromRow(rows.first);
  }

  void createUser({
    required String username,
    required String password,
    required String role,
  }) {
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    _db.execute(
      "INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)",
      [username.toLowerCase(), hash, role],
    );
  }

  void updatePasswordHash(String username, String newPasswordHash) {
    _db.execute(
      'UPDATE users SET password_hash = ? WHERE username = ?',
      [newPasswordHash, username.toLowerCase()],
    );
  }

  List<DbUser> getAllUsers() {
    final rows = _db.select('SELECT * FROM users ORDER BY created_at');
    return rows.map(DbUser._fromRow).toList();
  }

  /// Sets [active] and — when deactivating — bumps the token version so any
  /// outstanding JWTs for this user immediately fail auth checks.
  DbUser? setUserActive(String username, bool active) {
    _db.execute(
      'UPDATE users SET active = ?, '
      'token_version = token_version + CASE WHEN ? THEN 0 ELSE 1 END '
      'WHERE username = ?',
      [active ? 1 : 0, active ? 1 : 0, username.toLowerCase()],
    );
    return getUserByUsername(username);
  }

  DbUser? setUserRole(String username, String role) {
    _db.execute(
      'UPDATE users SET role = ? WHERE username = ?',
      [role, username.toLowerCase()],
    );
    return getUserByUsername(username);
  }

  /// Invalidates all outstanding JWTs for [username] without changing role
  /// or active state — used for a manual "force logout".
  DbUser? bumpTokenVersion(String username) {
    _db.execute(
      'UPDATE users SET token_version = token_version + 1 WHERE username = ?',
      [username.toLowerCase()],
    );
    return getUserByUsername(username);
  }

  bool deleteUser(String username) {
    _db.execute('DELETE FROM users WHERE username = ?', [username.toLowerCase()]);
    return _db.updatedRows > 0;
  }

  // ── OTP ────────────────────────────────────────────────────────────────────

  String generateAndStoreOtp(String username) {
    final otp = (100000 + Random().nextInt(900000)).toString();
    final expires = DateTime.now().add(const Duration(minutes: 10));
    _db.execute(
      'INSERT OR REPLACE INTO otp_tokens (username, otp, expires_at) VALUES (?, ?, ?)',
      [username.toLowerCase(), otp, expires.toIso8601String()],
    );
    return otp;
  }

  DbOtp? getOtp(String username) {
    final rows = _db.select(
      'SELECT * FROM otp_tokens WHERE username = ?',
      [username.toLowerCase()],
    );
    if (rows.isEmpty) return null;
    return DbOtp._fromRow(rows.first);
  }

  void deleteOtp(String username) {
    _db.execute(
      'DELETE FROM otp_tokens WHERE username = ?',
      [username.toLowerCase()],
    );
  }

  // ── Menu ───────────────────────────────────────────────────────────────────

  List<DbMenuItem> getMenuItems() {
    final rows = _db.select(
      'SELECT * FROM menu_items ORDER BY sort_order, category, name',
    );
    return rows.map(DbMenuItem._fromRow).toList();
  }

  DbMenuItem? getMenuItem(String id) {
    final rows = _db.select('SELECT * FROM menu_items WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return DbMenuItem._fromRow(rows.first);
  }

  DbMenuItem createMenuItem({
    required String name,
    required String category,
    required double price,
    bool available = true,
    String? imageBase64,
  }) {
    final id = 'u${_uuid.v4().substring(0, 8)}';
    final sortOrder = _db
        .select('SELECT COUNT(*) AS c FROM menu_items')
        .first['c'] as int;
    _db.execute(
      'INSERT INTO menu_items (id, name, category, price, available, sort_order, image_base64) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, name.trim(), category.trim(), price, available ? 1 : 0, sortOrder, imageBase64],
    );
    return getMenuItem(id)!;
  }

  DbMenuItem? updateMenuItem({
    required String id,
    required String name,
    required String category,
    required double price,
    required bool available,
    String? imageBase64,
  }) {
    _db.execute(
      'UPDATE menu_items SET name = ?, category = ?, price = ?, available = ?, image_base64 = ? '
      'WHERE id = ?',
      [name.trim(), category.trim(), price, available ? 1 : 0, imageBase64, id],
    );
    return getMenuItem(id);
  }

  bool deleteMenuItem(String id) {
    _db.execute('DELETE FROM menu_items WHERE id = ?', [id]);
    return _db.updatedRows > 0;
  }

  DbMenuItem? toggleMenuItem(String id) {
    _db.execute(
      'UPDATE menu_items SET available = 1 - available WHERE id = ?',
      [id],
    );
    return getMenuItem(id);
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  int _nextOrderNumber() {
    final rows = _db.select('SELECT MAX(order_number) AS m FROM orders');
    final max = rows.first['m'] as int?;
    return (max ?? 0) + 1;
  }

  DbOrder createOrder({
    required String paymentMethod,
    double? amountPaid,
    required List<Map<String, dynamic>> items,
  }) {
    final orderNumber = _nextOrderNumber();
    final now = DateTime.now().toIso8601String();
    final total = items.fold<double>(
      0,
      (s, i) => s + ((i['price'] as num).toDouble() * (i['quantity'] as int)),
    );

    _db.execute(
      'INSERT INTO orders (order_number, created_at, payment_method, amount_paid, total, status) '
      "VALUES (?, ?, ?, ?, ?, 'pending')",
      [orderNumber, now, paymentMethod, amountPaid, total],
    );
    final orderId = _db.lastInsertRowId;

    for (final item in items) {
      _db.execute(
        'INSERT INTO order_items '
        '(order_id, menu_item_id, menu_item_name, menu_item_category, price, quantity) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          orderId,
          item['menuItemId'],
          item['menuItemName'],
          item['menuItemCategory'],
          (item['price'] as num).toDouble(),
          item['quantity'],
        ],
      );
    }

    return _buildOrder(orderId, orderNumber, now, paymentMethod, amountPaid, total, 'pending');
  }

  DbOrder _buildOrder(
    int id,
    int orderNumber,
    String createdAt,
    String paymentMethod,
    double? amountPaid,
    double total,
    String status,
  ) {
    final itemRows = _db.select(
      'SELECT * FROM order_items WHERE order_id = ?',
      [id],
    );
    return DbOrder(
      id: id,
      orderNumber: orderNumber,
      createdAt: DateTime.parse(createdAt),
      paymentMethod: paymentMethod,
      total: total,
      amountPaid: amountPaid,
      status: status,
      items: itemRows.map(DbOrderItem._fromRow).toList(),
    );
  }

  DbOrder _rowToOrder(Row row) => _buildOrder(
        row['id'] as int,
        row['order_number'] as int,
        row['created_at'] as String,
        row['payment_method'] as String,
        row['amount_paid'] as double?,
        (row['total'] as num).toDouble(),
        row['status'] as String,
      );

  List<DbOrder> getOrders({String? date}) {
    final buffer = StringBuffer(
      'SELECT o.id, o.order_number, o.created_at, o.payment_method, '
      'o.amount_paid, o.total, o.status FROM orders o',
    );
    final args = <Object?>[];

    if (date != null) {
      buffer.write(' WHERE DATE(o.created_at) = ?');
      args.add(date);
    }
    buffer.write(' ORDER BY o.id DESC');

    final orderRows = _db.select(buffer.toString(), args);
    return orderRows.map(_rowToOrder).toList();
  }

  /// Orders still in the kitchen pipeline (not yet completed), oldest first.
  List<DbOrder> getActiveOrders() {
    final rows = _db.select(
      "SELECT id, order_number, created_at, payment_method, amount_paid, total, status "
      "FROM orders WHERE status != 'completed' ORDER BY id ASC",
    );
    return rows.map(_rowToOrder).toList();
  }

  DbOrder? getOrderById(int id) {
    final rows = _db.select(
      'SELECT id, order_number, created_at, payment_method, amount_paid, total, status '
      'FROM orders WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToOrder(rows.first);
  }

  DbOrder? updateOrderStatus(int id, String status) {
    _db.execute('UPDATE orders SET status = ? WHERE id = ?', [status, id]);
    if (_db.updatedRows == 0) return null;
    return getOrderById(id);
  }

  /// Updates one item's prep status, then re-derives and persists the
  /// parent order's own status from all its items: 'pending' if every item
  /// is still pending, 'ready' once every item is ready, 'preparing'
  /// otherwise. 'completed' is never derived here — that's an explicit,
  /// order-level-only action via [updateOrderStatus].
  DbOrder? updateOrderItemStatus(int orderId, int itemId, String status) {
    _db.execute(
      'UPDATE order_items SET status = ? WHERE id = ? AND order_id = ?',
      [status, itemId, orderId],
    );
    if (_db.updatedRows == 0) return null;

    final order = getOrderById(orderId);
    if (order == null) return null;
    if (order.status == 'completed') return order;

    final itemStatuses = order.items.map((i) => i.status).toSet();
    final derived = itemStatuses.every((s) => s == 'pending')
        ? 'pending'
        : itemStatuses.every((s) => s == 'ready')
            ? 'ready'
            : 'preparing';
    if (derived == order.status) return order;

    _db.execute('UPDATE orders SET status = ? WHERE id = ?', [derived, orderId]);
    return getOrderById(orderId);
  }

  Map<String, dynamic> getOrderStats({String? date}) {
    final where = date != null ? "WHERE DATE(created_at) = '$date'" : '';
    final rows = _db.select(
      'SELECT COUNT(*) AS cnt, COALESCE(SUM(total), 0) AS rev '
      'FROM orders $where',
    );
    final row = rows.first;
    return {
      'count': row['cnt'] as int,
      'revenue': (row['rev'] as num).toDouble(),
    };
  }

  // ── Default menu seed ──────────────────────────────────────────────────────

  void _seedMenu() {
    const items = [
      ('c1', 'Espresso', 'Coffee', 65.0),
      ('c2', 'Americano', 'Coffee', 75.0),
      ('c3', 'Latte', 'Coffee', 90.0),
      ('c4', 'Cappuccino', 'Coffee', 90.0),
      ('c5', 'Mocha', 'Coffee', 95.0),
      ('c6', 'Flat White', 'Coffee', 95.0),
      ('c7', 'Macchiato', 'Coffee', 85.0),
      ('c8', 'Cold Brew', 'Coffee', 100.0),
      ('t1', 'Thai Milk Tea', 'Tea', 65.0),
      ('t2', 'Green Tea Latte', 'Tea', 85.0),
      ('t3', 'Matcha Latte', 'Tea', 95.0),
      ('t4', 'Chamomile', 'Tea', 70.0),
      ('t5', 'Earl Grey', 'Tea', 70.0),
      ('k1', 'Fresh Orange', 'Cold', 75.0),
      ('k2', 'Lemonade', 'Cold', 70.0),
      ('k3', 'Strawberry Smoothie', 'Cold', 95.0),
      ('k4', 'Mango Smoothie', 'Cold', 95.0),
      ('k5', 'Iced Chocolate', 'Cold', 90.0),
      ('f1', 'Croissant', 'Food', 65.0),
      ('f2', 'Toast & Jam', 'Food', 55.0),
      ('f3', 'Club Sandwich', 'Food', 120.0),
      ('f4', 'Banana Cake', 'Food', 70.0),
      ('f5', 'Choco Muffin', 'Food', 75.0),
      ('f6', 'Waffle', 'Food', 110.0),
    ];

    for (var i = 0; i < items.length; i++) {
      final (id, name, cat, price) = items[i];
      _db.execute(
        'INSERT OR IGNORE INTO menu_items (id, name, category, price, available, sort_order) '
        'VALUES (?, ?, ?, ?, 1, ?)',
        [id, name, cat, price, i],
      );
    }
  }
}
