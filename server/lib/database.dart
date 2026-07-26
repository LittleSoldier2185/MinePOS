import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:uuid/uuid.dart';

import 'config.dart';
import 'server_log.dart';

const _uuid = Uuid();

// ── Domain models ─────────────────────────────────────────────────────────────

class DbUser {
  DbUser({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.active,
    required this.tokenVersion,
    required this.createdAt,
    this.name,
    this.email,
    this.phone,
    this.avatarBase64,
  });

  final int id;
  final String username;
  final String passwordHash;
  final String role;
  final bool active;
  final int tokenVersion;
  final DateTime createdAt;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatarBase64;

  factory DbUser._fromRow(Row row) => DbUser(
        id: row['id'] as int,
        username: row['username'] as String,
        passwordHash: row['password_hash'] as String,
        role: row['role'] as String,
        active: (row['active'] as int) == 1,
        tokenVersion: row['token_version'] as int,
        createdAt: DateTime.parse(row['created_at'] as String),
        name: row['name'] as String?,
        email: row['email'] as String?,
        phone: row['phone'] as String?,
        avatarBase64: row['avatar_base64'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'role': role,
        'active': active,
        'createdAt': createdAt.toIso8601String(),
        'name': name,
        'email': email,
        'phone': phone,
        'avatarBase64': avatarBase64,
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
    this.hasSweetness = false,
    this.nameTh,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final bool available;
  final String? imageBase64;
  final bool hasSweetness;

  /// Optional Thai translation of [name].
  final String? nameTh;

  factory DbMenuItem._fromRow(Row row) => DbMenuItem(
        id: row['id'] as String,
        name: row['name'] as String,
        category: row['category'] as String,
        price: (row['price'] as num).toDouble(),
        available: (row['available'] as int) == 1,
        imageBase64: row['image_base64'] as String?,
        hasSweetness: (row['has_sweetness'] as int? ?? 0) == 1,
        nameTh: row['name_th'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'price': price,
        'available': available,
        'imageBase64': imageBase64,
        'hasSweetness': hasSweetness,
        'nameTh': nameTh,
      };
}

class DbAdSlide {
  DbAdSlide({
    required this.id,
    required this.type,
    required this.filename,
    required this.position,
    this.durationSeconds,
    this.muted = true,
  });

  final String id;

  /// 'image' or 'video' — a GIF is stored/served as 'image'.
  final String type;
  final String filename;
  final int position;

  /// Only meaningful for image/gif; null for video (plays to its own end).
  final int? durationSeconds;

  /// Only meaningful for video — images have no audio to mute.
  final bool muted;

  factory DbAdSlide._fromRow(Row row) => DbAdSlide(
        id: row['id'] as String,
        type: row['type'] as String,
        filename: row['filename'] as String,
        position: row['position'] as int,
        durationSeconds: row['duration_seconds'] as int?,
        muted: (row['muted'] as int) != 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'durationSeconds': durationSeconds,
        'muted': muted,
        // Relative path only — both the authenticated GET /ads response
        // (Settings screen) and the unauthenticated WebSocket broadcast
        // (customer display) share this one field, client prefixes baseUrl.
        'url': '/ads/$id/file',
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
    this.sweetness,
    this.menuItemNameTh,
    this.discountAmount = 0,
  });

  final int id;
  final String menuItemId;
  final String menuItemName;
  final String menuItemCategory;
  final double price;
  final int quantity;

  /// This line's share of whatever promotion(s) applied — set by the client
  /// (which already computed it via `PromotionService.evaluate`), stored
  /// here purely for receipt/report line-item detail. See [DbOrder.total]'s
  /// sibling [DbOrder.discountTotal] for the order-level sum.
  final double discountAmount;

  /// Per-item kitchen prep state: one of [kOrderItemStatuses]. Unlike the
  /// parent order's status, an item never reaches "completed" on its own —
  /// serving the whole order is an order-level action.
  final String status;

  /// One of "less" | "normal" | "sweet", only set for items ordered from a
  /// menu item flagged [DbMenuItem.hasSweetness].
  final String? sweetness;

  /// Thai translation of [menuItemName], snapshotted at order time — same
  /// reasoning as [menuItemName] itself: decoupled from the live menu item,
  /// which may be renamed or deleted later.
  final String? menuItemNameTh;

  factory DbOrderItem._fromRow(Row row) => DbOrderItem(
        id: row['id'] as int,
        menuItemId: row['menu_item_id'] as String,
        menuItemName: row['menu_item_name'] as String,
        menuItemCategory: row['menu_item_category'] as String,
        price: (row['price'] as num).toDouble(),
        quantity: row['quantity'] as int,
        status: row['status'] as String? ?? 'pending',
        sweetness: row['sweetness'] as String?,
        menuItemNameTh: row['menu_item_name_th'] as String?,
        discountAmount: (row['discount_amount'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'menuItemId': menuItemId,
        'menuItemName': menuItemName,
        'menuItemCategory': menuItemCategory,
        'price': price,
        'quantity': quantity,
        'status': status,
        'sweetness': sweetness,
        'menuItemNameTh': menuItemNameTh,
        'discountAmount': discountAmount,
      };

  double get subtotal => price * quantity;
}

/// Kitchen prep states an order moves through, oldest-first. 'cancelled' is
/// a terminal state reached only from 'pending' (see [AppDb.cancelOrder]),
/// never derived from item statuses like the others.
const kOrderStatuses = ['pending', 'preparing', 'ready', 'completed', 'cancelled'];

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
    this.cancelReason,
    this.discountTotal = 0,
    this.appliedPromotions = const [],
    this.createdByUserId,
    this.createdByName,
  });

  final int id;
  final int orderNumber;
  final DateTime createdAt;
  final String paymentMethod;

  /// Already net of [discountTotal] — the client sends the final
  /// post-discount total same as it always has, promotions are just another
  /// input to the price the client was already authoritative for.
  final double total;
  final double? amountPaid;
  final String status;
  final List<DbOrderItem> items;

  /// Set only when [status] is 'cancelled' — the reason chosen (plus any
  /// free-text detail) at cancel time.
  final String? cancelReason;

  /// Sum of every applied promotion's discount — same number as summing
  /// [appliedPromotions], kept as its own column for cheap Reports queries.
  final double discountTotal;

  /// Audit trail: which promotion(s) applied to this order, populated from
  /// `order_promotions` (see [AppDb.recordOrderPromotions]).
  final List<DbAppliedPromotion> appliedPromotions;

  /// Which staff member rang this up — null for orders placed before this
  /// column existed. [createdByName] is a snapshot of that user's display
  /// name at order time (same reasoning as [DbOrderItem.menuItemName]): a
  /// later rename/deletion of the account shouldn't break past sales
  /// attribution in Reports.
  final int? createdByUserId;
  final String? createdByName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'createdAt': createdAt.toIso8601String(),
        'paymentMethod': paymentMethod,
        'status': status,
        'total': total,
        'amountPaid': amountPaid,
        'cancelReason': cancelReason,
        'items': items.map((i) => i.toJson()).toList(),
        'discountTotal': discountTotal,
        'appliedPromotions': appliedPromotions.map((p) => p.toJson()).toList(),
        'createdByUserId': createdByUserId,
        'createdByName': createdByName,
      };
}

/// One row of `order_promotions` — a promotion that applied to a specific
/// order, joined with the promotion's own name for display without a
/// separate lookup.
class DbAppliedPromotion {
  DbAppliedPromotion({
    required this.promotionId,
    required this.name,
    required this.discountAmount,
    this.codeUsed,
    this.approvedByUserId,
  });

  final String promotionId;
  final String name;
  final double discountAmount;
  final String? codeUsed;
  final int? approvedByUserId;

  Map<String, dynamic> toJson() => {
        'promotionId': promotionId,
        'name': name,
        'discountAmount': discountAmount,
        'codeUsed': codeUsed,
        'approvedByUserId': approvedByUserId,
      };
}

/// A configured promotion. Which of the nullable mechanics fields are
/// meaningful depends on [type]:
///  - 'percent': [percentValue] (+ optional [maxDiscountCap])
///  - 'flat': [flatAmount]
///  - 'bogo': [bogoBuyQty]/[bogoGetQty]/[bogoGetDiscountPercent]
///  - 'code': no mechanics of its own here — see [codes]; a code promotion's
///    actual discount shape (percent/flat) is still expressed via
///    [percentValue]/[flatAmount], the code just gates whether it applies
///  - 'combo': [comboPrice]
///  - 'min_spend': [minSpendAmount] (+ [percentValue] or [flatAmount] for
///    what the reward actually is)
///  - 'tiered': [tiered]
/// See `PromotionService` (client) for the evaluation logic that actually
/// interprets these against a cart.
class DbPromotion {
  DbPromotion({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    required this.scopeType,
    this.scopeItemIds = const [],
    this.scopeCategory,
    this.excludeItemIds = const [],
    this.percentValue,
    this.flatAmount,
    this.maxDiscountCap,
    this.minSpendAmount,
    this.bogoBuyQty,
    this.bogoGetQty,
    this.bogoGetDiscountPercent,
    this.comboPrice,
    this.tiered = const [],
    this.startDate,
    this.endDate,
    this.daysOfWeek,
    this.timeStart,
    this.timeEnd,
    this.requiresManagerApproval = false,
    this.approvalThresholdAmount,
    required this.createdAt,
    this.codes = const [],
  });

  final String id;
  final String name;
  final String type;
  final bool active;

  final String scopeType;
  final List<String> scopeItemIds;
  final String? scopeCategory;
  final List<String> excludeItemIds;

  final double? percentValue;
  final double? flatAmount;
  final double? maxDiscountCap;
  final double? minSpendAmount;
  final int? bogoBuyQty;
  final int? bogoGetQty;
  final double? bogoGetDiscountPercent;
  final double? comboPrice;
  final List<Map<String, dynamic>> tiered;

  /// Scheduled window — both a date range AND a recurring day/time window
  /// can be set at once (all non-null constraints must hold simultaneously
  /// for the promotion to be "in window" right now); either or both may be
  /// left null, in which case that constraint just doesn't restrict it.
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? daysOfWeek;
  final String? timeStart;
  final String? timeEnd;

  final bool requiresManagerApproval;
  final double? approvalThresholdAmount;

  final DateTime createdAt;

  /// Only populated for `type == 'code'` promotions.
  final List<DbPromotionCode> codes;

  factory DbPromotion._fromRow(Row row, {List<DbPromotionCode> codes = const []}) =>
      DbPromotion(
        id: row['id'] as String,
        name: row['name'] as String,
        type: row['type'] as String,
        active: (row['active'] as int) == 1,
        scopeType: row['scope_type'] as String,
        scopeItemIds: _decodeStringList(row['scope_item_ids'] as String?),
        scopeCategory: row['scope_category'] as String?,
        excludeItemIds: _decodeStringList(row['exclude_item_ids'] as String?),
        percentValue: (row['percent_value'] as num?)?.toDouble(),
        flatAmount: (row['flat_amount'] as num?)?.toDouble(),
        maxDiscountCap: (row['max_discount_cap'] as num?)?.toDouble(),
        minSpendAmount: (row['min_spend_amount'] as num?)?.toDouble(),
        bogoBuyQty: row['bogo_buy_qty'] as int?,
        bogoGetQty: row['bogo_get_qty'] as int?,
        bogoGetDiscountPercent: (row['bogo_get_discount_percent'] as num?)?.toDouble(),
        comboPrice: (row['combo_price'] as num?)?.toDouble(),
        tiered: _decodeTiered(row['tiered_json'] as String?),
        startDate: row['start_date'] != null ? DateTime.parse(row['start_date'] as String) : null,
        endDate: row['end_date'] != null ? DateTime.parse(row['end_date'] as String) : null,
        daysOfWeek: row['days_of_week'] != null
            ? (jsonDecode(row['days_of_week'] as String) as List).cast<int>()
            : null,
        timeStart: row['time_start'] as String?,
        timeEnd: row['time_end'] as String?,
        requiresManagerApproval: (row['requires_manager_approval'] as int) == 1,
        approvalThresholdAmount: (row['approval_threshold_amount'] as num?)?.toDouble(),
        createdAt: DateTime.parse(row['created_at'] as String),
        codes: codes,
      );

  static List<String> _decodeStringList(String? json) {
    if (json == null) return const [];
    return (jsonDecode(json) as List).cast<String>();
  }

  static List<Map<String, dynamic>> _decodeTiered(String? json) {
    if (json == null) return const [];
    return (jsonDecode(json) as List).cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'active': active,
        'scopeType': scopeType,
        'scopeItemIds': scopeItemIds,
        'scopeCategory': scopeCategory,
        'excludeItemIds': excludeItemIds,
        'percentValue': percentValue,
        'flatAmount': flatAmount,
        'maxDiscountCap': maxDiscountCap,
        'minSpendAmount': minSpendAmount,
        'bogoBuyQty': bogoBuyQty,
        'bogoGetQty': bogoGetQty,
        'bogoGetDiscountPercent': bogoGetDiscountPercent,
        'comboPrice': comboPrice,
        'tiered': tiered,
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'daysOfWeek': daysOfWeek,
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        'requiresManagerApproval': requiresManagerApproval,
        'approvalThresholdAmount': approvalThresholdAmount,
        'createdAt': createdAt.toIso8601String(),
        'codes': codes.map((c) => c.toJson()).toList(),
      };
}

/// One redeemable code attached to a `type == 'code'` promotion — split
/// into its own table/model since a single promotion can have many codes
/// (e.g. a batch of one-time codes for a mailer), each with its own
/// [maxUses]/[usedCount].
class DbPromotionCode {
  DbPromotionCode({
    required this.id,
    required this.promotionId,
    required this.code,
    this.maxUses,
    this.usedCount = 0,
  });

  final String id;
  final String promotionId;

  /// Stored uppercase; compared case-insensitively everywhere.
  final String code;
  final int? maxUses;
  final int usedCount;

  factory DbPromotionCode._fromRow(Row row) => DbPromotionCode(
        id: row['id'] as String,
        promotionId: row['promotion_id'] as String,
        code: row['code'] as String,
        maxUses: row['max_uses'] as int?,
        usedCount: row['used_count'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'promotionId': promotionId,
        'code': code,
        'maxUses': maxUses,
        'usedCount': usedCount,
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
      // Password stays console-only — the persisted log below is redacted so
      // it never lands somewhere the in-app log viewer (or the disk) shows it.
      ServerLog.instance.log(
          'Created admin user "${config.adminUser}" (password shown in console output only, not persisted)');
    }

    // Seed default menu if empty.
    if (instance.getMenuItems().isEmpty) {
      instance._seedMenu();
    }

    return instance;
  }

  /// Releases the native sqlite3 connection. Callers that reopen a fresh
  /// [AppDb] afterward (e.g. an in-process server restart) must call this
  /// first, or the old native handle leaks for the life of the process.
  void close() => _db.dispose();

  /// Writes a consistent, defragmented snapshot of the whole database to
  /// [path] via SQLite's own `VACUUM INTO` — an atomic hot-backup mechanism
  /// that's safe to run while the live server keeps serving reads/writes
  /// (unlike copying the raw .db file's bytes, which could catch a write
  /// mid-transaction). Used by `GET /admin/backup` to produce a snapshot for
  /// moving the shop to a new device. [path] must not already exist.
  void exportSnapshotTo(String path) {
    _db.execute('VACUUM INTO ?', [path]);
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
    if (!userCols.contains('email')) {
      _db.execute('ALTER TABLE users ADD COLUMN email TEXT');
    }
    if (!userCols.contains('phone')) {
      _db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
    }
    if (!userCols.contains('avatar_base64')) {
      _db.execute('ALTER TABLE users ADD COLUMN avatar_base64 TEXT');
    }
    if (!userCols.contains('name')) {
      _db.execute('ALTER TABLE users ADD COLUMN name TEXT');
    }
    // One-time rebuild: username used to be the PK (and the identifier used
    // in routes/JWTs), which made it impossible to rename a user without
    // breaking their own row's identity. Numeric `id` is now the real key;
    // `username` becomes an ordinary unique column. Runs once per DB — later
    // opens see `id` already present and skip straight past this block.
    if (!userCols.contains('id')) {
      _db.execute('ALTER TABLE users RENAME TO users_old');
      _db.execute('''
        CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          password_hash TEXT NOT NULL,
          role TEXT NOT NULL DEFAULT 'worker',
          active INTEGER NOT NULL DEFAULT 1,
          token_version INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL DEFAULT (datetime('now')),
          name TEXT,
          email TEXT,
          phone TEXT,
          avatar_base64 TEXT
        )
      ''');
      _db.execute('''
        INSERT INTO users (username, password_hash, role, active,
                            token_version, created_at, name, email, phone,
                            avatar_base64)
          SELECT username, password_hash, role, active, token_version,
                 created_at, name, email, phone, avatar_base64
          FROM users_old ORDER BY created_at
      ''');
      _db.execute('DROP TABLE users_old');
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
    if (!menuCols.contains('has_sweetness')) {
      _db.execute(
          'ALTER TABLE menu_items ADD COLUMN has_sweetness INTEGER NOT NULL DEFAULT 0');
    }
    if (!menuCols.contains('name_th')) {
      _db.execute('ALTER TABLE menu_items ADD COLUMN name_th TEXT');
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
    if (!orderCols.contains('cancel_reason')) {
      _db.execute('ALTER TABLE orders ADD COLUMN cancel_reason TEXT');
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
    if (!itemCols.contains('sweetness')) {
      _db.execute('ALTER TABLE order_items ADD COLUMN sweetness TEXT');
    }
    if (!itemCols.contains('menu_item_name_th')) {
      _db.execute('ALTER TABLE order_items ADD COLUMN menu_item_name_th TEXT');
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
    final shopCols = _db
        .select("PRAGMA table_info(shop_config)")
        .map((r) => r['name'])
        .toSet();
    if (!shopCols.contains('promptpay_id')) {
      _db.execute('ALTER TABLE shop_config ADD COLUMN promptpay_id TEXT');
    }
    if (!shopCols.contains('promptpay_label')) {
      _db.execute('ALTER TABLE shop_config ADD COLUMN promptpay_label TEXT');
    }

    // Customer-display advertising slideshow — shop-wide, not per-station.
    // `type` is 'image' or 'video' (an animated GIF is stored/served as
    // 'image'; Flutter's Image widget already animates GIFs natively).
    // `duration_seconds` only applies to image/gif slides — null for video,
    // which plays to its own natural end before advancing.
    _db.execute('''
      CREATE TABLE IF NOT EXISTS ad_slides (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        filename TEXT NOT NULL,
        duration_seconds INTEGER,
        position INTEGER NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    final adSlideCols = _db
        .select('PRAGMA table_info(ad_slides)')
        .map((r) => r['name'])
        .toSet();
    if (!adSlideCols.contains('muted')) {
      // Video only (ignored/meaningless for images) — defaults to muted
      // since unexpected audio on a customer-facing display is the
      // riskier default for a shop floor.
      _db.execute('ALTER TABLE ad_slides ADD COLUMN muted INTEGER NOT NULL DEFAULT 1');
    }

    // Promotions — see PromotionService (client) for how these get evaluated
    // against a cart. Nullable mechanics columns are only meaningful for the
    // matching `type`; scope/schedule columns hold JSON arrays or plain
    // strings since sqlite has no native array/date type.
    _db.execute('''
      CREATE TABLE IF NOT EXISTS promotions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,

        scope_type TEXT NOT NULL,
        scope_item_ids TEXT,
        scope_category TEXT,
        exclude_item_ids TEXT,

        percent_value REAL,
        flat_amount REAL,
        max_discount_cap REAL,
        min_spend_amount REAL,
        bogo_buy_qty INTEGER,
        bogo_get_qty INTEGER,
        bogo_get_discount_percent REAL,
        combo_price REAL,
        tiered_json TEXT,

        start_date TEXT,
        end_date TEXT,
        days_of_week TEXT,
        time_start TEXT,
        time_end TEXT,

        requires_manager_approval INTEGER NOT NULL DEFAULT 0,
        approval_threshold_amount REAL,

        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Codes for a `type = 'code'` promotion — split into its own table
    // (rather than a single column on `promotions`) since one promotion can
    // have several codes (e.g. a batch of one-time codes for a mailer).
    _db.execute('''
      CREATE TABLE IF NOT EXISTS promotion_codes (
        id TEXT PRIMARY KEY,
        promotion_id TEXT NOT NULL,
        code TEXT NOT NULL,
        max_uses INTEGER,
        used_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Audit trail + per-order attribution — a dedicated join table rather
    // than a column on `orders` because promotions can stack (multiple rows
    // per order).
    _db.execute('''
      CREATE TABLE IF NOT EXISTS order_promotions (
        order_id INTEGER NOT NULL,
        promotion_id TEXT NOT NULL,
        code_used TEXT,
        discount_amount REAL NOT NULL,
        approved_by_user_id INTEGER,
        PRIMARY KEY (order_id, promotion_id)
      )
    ''');

    final orderCols2 =
        _db.select("PRAGMA table_info(orders)").map((r) => r['name']).toSet();
    if (!orderCols2.contains('discount_total')) {
      _db.execute(
          'ALTER TABLE orders ADD COLUMN discount_total REAL NOT NULL DEFAULT 0');
    }
    final orderItemCols2 = _db
        .select("PRAGMA table_info(order_items)")
        .map((r) => r['name'])
        .toSet();
    if (!orderItemCols2.contains('discount_amount')) {
      _db.execute(
          'ALTER TABLE order_items ADD COLUMN discount_amount REAL NOT NULL DEFAULT 0');
    }

    // Which staff member rang up this order — nullable since orders placed
    // before this column existed have neither. `created_by_name` is a
    // snapshot of the actor's display name at order time (same reasoning as
    // `order_items.menu_item_name`: a later rename/deletion of that staff
    // account shouldn't break past sales attribution in Reports).
    if (!orderCols2.contains('created_by_user_id')) {
      _db.execute('ALTER TABLE orders ADD COLUMN created_by_user_id INTEGER');
    }
    if (!orderCols2.contains('created_by_name')) {
      _db.execute('ALTER TABLE orders ADD COLUMN created_by_name TEXT');
    }
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
      'promptPayId': row['promptpay_id'],
      'promptPayLabel': row['promptpay_label'],
    };
  }

  void setShopConfig({
    required String shopName,
    String? address,
    String? taxId,
    String? email,
    String? receiptFooter,
    String? promptPayId,
    String? promptPayLabel,
  }) {
    _db.execute(
      'INSERT OR REPLACE INTO shop_config '
      '(id, shop_name, address, tax_id, email, receipt_footer, promptpay_id, promptpay_label) '
      'VALUES (1, ?, ?, ?, ?, ?, ?, ?)',
      [shopName, address, taxId, email, receiptFooter, promptPayId, promptPayLabel],
    );
  }

  /// Wipes every row from every table — shop config, all accounts, menu,
  /// orders, ad slides — resetting the server to the same pristine state as
  /// before POST /setup was ever called, so a new shop can be bootstrapped
  /// again. Existing JWTs for the deleted owner stop working immediately
  /// since [verifyToken] looks the user up by username on every request.
  ///
  /// Returns the filenames of any wiped ad slides so the caller (which has
  /// [ServerConfig.dataDir], unlike this DB-only class) can delete the
  /// actual files from disk too — otherwise they'd linger as orphans, the
  /// same kind of leftover-file confusion `minepos.db` itself caused before
  /// `hasLocalShop()` was fixed to check for real rows instead of mere file
  /// existence.
  List<String> wipeShop() {
    final adFilenames =
        _db.select('SELECT filename FROM ad_slides').map((r) => r['filename'] as String).toList();
    _db.execute('DELETE FROM order_promotions');
    _db.execute('DELETE FROM order_items');
    _db.execute('DELETE FROM orders');
    _db.execute('DELETE FROM menu_items');
    _db.execute('DELETE FROM otp_tokens');
    _db.execute('DELETE FROM users');
    _db.execute('DELETE FROM shop_config');
    _db.execute('DELETE FROM ad_slides');
    _db.execute('DELETE FROM promotion_codes');
    _db.execute('DELETE FROM promotions');
    return adFilenames;
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

  DbUser? getUserById(int id) {
    final rows = _db.select('SELECT * FROM users WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return DbUser._fromRow(rows.first);
  }

  void createUser({
    required String username,
    required String password,
    required String role,
    String? name,
    String? email,
    String? phone,
    String? avatarBase64,
  }) {
    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    _db.execute(
      'INSERT INTO users (username, password_hash, role, name, email, phone, avatar_base64) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [username.toLowerCase(), hash, role, name, email, phone, avatarBase64],
    );
  }

  /// Renames a user. Uniqueness against other users is the caller's
  /// responsibility (checked via [getUserByUsername] before calling this).
  DbUser? updateUsername(int id, String newUsername) {
    _db.execute(
      'UPDATE users SET username = ? WHERE id = ?',
      [newUsername.toLowerCase(), id],
    );
    return getUserById(id);
  }

  void updatePasswordHash(int id, String newPasswordHash) {
    _db.execute(
      'UPDATE users SET password_hash = ? WHERE id = ?',
      [newPasswordHash, id],
    );
  }

  /// Updates a user's contact/profile fields (not security-sensitive, unlike
  /// role/active/password — no self-edit restrictions apply to these).
  DbUser? updateUserProfile(
    int id, {
    String? name,
    String? email,
    String? phone,
    String? avatarBase64,
  }) {
    _db.execute(
      'UPDATE users SET name = ?, email = ?, phone = ?, avatar_base64 = ? WHERE id = ?',
      [name, email, phone, avatarBase64, id],
    );
    return getUserById(id);
  }

  List<DbUser> getAllUsers() {
    final rows = _db.select('SELECT * FROM users ORDER BY created_at');
    return rows.map(DbUser._fromRow).toList();
  }

  /// Sets [active] and — when deactivating — bumps the token version so any
  /// outstanding JWTs for this user immediately fail auth checks.
  DbUser? setUserActive(int id, bool active) {
    _db.execute(
      'UPDATE users SET active = ?, '
      'token_version = token_version + CASE WHEN ? THEN 0 ELSE 1 END '
      'WHERE id = ?',
      [active ? 1 : 0, active ? 1 : 0, id],
    );
    return getUserById(id);
  }

  DbUser? setUserRole(int id, String role) {
    _db.execute(
      'UPDATE users SET role = ? WHERE id = ?',
      [role, id],
    );
    return getUserById(id);
  }

  /// Invalidates all outstanding JWTs for [id] without changing role or
  /// active state — used for a manual "force logout".
  DbUser? bumpTokenVersion(int id) {
    _db.execute(
      'UPDATE users SET token_version = token_version + 1 WHERE id = ?',
      [id],
    );
    return getUserById(id);
  }

  bool deleteUser(int id) {
    _db.execute('DELETE FROM users WHERE id = ?', [id]);
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
    bool hasSweetness = false,
    String? nameTh,
  }) {
    final id = 'u${_uuid.v4().substring(0, 8)}';
    final sortOrder = _db
        .select('SELECT COUNT(*) AS c FROM menu_items')
        .first['c'] as int;
    _db.execute(
      'INSERT INTO menu_items (id, name, category, price, available, sort_order, image_base64, has_sweetness, name_th) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [id, name.trim(), category.trim(), price, available ? 1 : 0, sortOrder, imageBase64,
          hasSweetness ? 1 : 0, nameTh],
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
    bool hasSweetness = false,
    String? nameTh,
  }) {
    _db.execute(
      'UPDATE menu_items SET name = ?, category = ?, price = ?, available = ?, image_base64 = ?, '
      'has_sweetness = ?, name_th = ? WHERE id = ?',
      [name.trim(), category.trim(), price, available ? 1 : 0, imageBase64,
          hasSweetness ? 1 : 0, nameTh, id],
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

  // ── Ad slides (customer-display advertising slideshow) ──────────────────────

  List<DbAdSlide> getAdSlides() {
    final rows = _db.select('SELECT * FROM ad_slides ORDER BY position');
    return rows.map(DbAdSlide._fromRow).toList();
  }

  DbAdSlide? getAdSlide(String id) {
    final rows = _db.select('SELECT * FROM ad_slides WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return DbAdSlide._fromRow(rows.first);
  }

  DbAdSlide createAdSlide({
    required String type,
    required String filename,
    int? durationSeconds,
  }) {
    final id = _uuid.v4().substring(0, 8);
    final position = _db
        .select('SELECT COUNT(*) AS c FROM ad_slides')
        .first['c'] as int;
    _db.execute(
      'INSERT INTO ad_slides (id, type, filename, duration_seconds, position) '
      'VALUES (?, ?, ?, ?, ?)',
      [id, type, filename, durationSeconds, position],
    );
    return getAdSlide(id)!;
  }

  DbAdSlide? updateAdSlideDuration(String id, int durationSeconds) {
    _db.execute(
      'UPDATE ad_slides SET duration_seconds = ? WHERE id = ?',
      [durationSeconds, id],
    );
    return getAdSlide(id);
  }

  DbAdSlide? updateAdSlideMuted(String id, bool muted) {
    _db.execute(
      'UPDATE ad_slides SET muted = ? WHERE id = ?',
      [muted ? 1 : 0, id],
    );
    return getAdSlide(id);
  }

  /// Rewrites every slide's `position` to match [orderedIds]'s index —
  /// unknown ids are ignored (e.g. a slide deleted on another device just
  /// before this request landed).
  void reorderAdSlides(List<String> orderedIds) {
    for (var i = 0; i < orderedIds.length; i++) {
      _db.execute('UPDATE ad_slides SET position = ? WHERE id = ?', [i, orderedIds[i]]);
    }
  }

  /// Returns the deleted slide's filename (so the route can remove the
  /// actual file from disk), or null if no slide with [id] existed.
  String? deleteAdSlide(String id) {
    final slide = getAdSlide(id);
    if (slide == null) return null;
    _db.execute('DELETE FROM ad_slides WHERE id = ?', [id]);
    return slide.filename;
  }

  // ── Promotions ───────────────────────────────────────────────────────────────

  static const _promotionColumns =
      'id, name, type, active, scope_type, scope_item_ids, scope_category, exclude_item_ids, '
      'percent_value, flat_amount, max_discount_cap, min_spend_amount, bogo_buy_qty, bogo_get_qty, '
      'bogo_get_discount_percent, combo_price, tiered_json, start_date, end_date, days_of_week, '
      'time_start, time_end, requires_manager_approval, approval_threshold_amount, created_at';

  List<DbPromotionCode> _codesFor(String promotionId) => _db
      .select('SELECT * FROM promotion_codes WHERE promotion_id = ?', [promotionId])
      .map(DbPromotionCode._fromRow)
      .toList();

  List<DbPromotion> getPromotions() {
    final rows = _db.select('SELECT $_promotionColumns FROM promotions ORDER BY created_at');
    return rows.map((row) => DbPromotion._fromRow(row, codes: _codesFor(row['id'] as String))).toList();
  }

  DbPromotion? getPromotion(String id) {
    final rows = _db.select('SELECT $_promotionColumns FROM promotions WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return DbPromotion._fromRow(rows.first, codes: _codesFor(id));
  }

  DbPromotion createPromotion({
    required String name,
    required String type,
    bool active = true,
    required String scopeType,
    List<String> scopeItemIds = const [],
    String? scopeCategory,
    List<String> excludeItemIds = const [],
    double? percentValue,
    double? flatAmount,
    double? maxDiscountCap,
    double? minSpendAmount,
    int? bogoBuyQty,
    int? bogoGetQty,
    double? bogoGetDiscountPercent,
    double? comboPrice,
    List<Map<String, dynamic>> tiered = const [],
    DateTime? startDate,
    DateTime? endDate,
    List<int>? daysOfWeek,
    String? timeStart,
    String? timeEnd,
    bool requiresManagerApproval = false,
    double? approvalThresholdAmount,
  }) {
    final id = _uuid.v4().substring(0, 8);
    _db.execute(
      'INSERT INTO promotions ($_promotionColumns) VALUES '
      "(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime('now'))",
      [
        id,
        name.trim(),
        type,
        active ? 1 : 0,
        scopeType,
        scopeItemIds.isEmpty ? null : jsonEncode(scopeItemIds),
        scopeCategory,
        excludeItemIds.isEmpty ? null : jsonEncode(excludeItemIds),
        percentValue,
        flatAmount,
        maxDiscountCap,
        minSpendAmount,
        bogoBuyQty,
        bogoGetQty,
        bogoGetDiscountPercent,
        comboPrice,
        tiered.isEmpty ? null : jsonEncode(tiered),
        startDate?.toIso8601String(),
        endDate?.toIso8601String(),
        daysOfWeek == null ? null : jsonEncode(daysOfWeek),
        timeStart,
        timeEnd,
        requiresManagerApproval ? 1 : 0,
        approvalThresholdAmount,
      ],
    );
    return getPromotion(id)!;
  }

  DbPromotion? updatePromotion({
    required String id,
    required String name,
    required String type,
    required bool active,
    required String scopeType,
    List<String> scopeItemIds = const [],
    String? scopeCategory,
    List<String> excludeItemIds = const [],
    double? percentValue,
    double? flatAmount,
    double? maxDiscountCap,
    double? minSpendAmount,
    int? bogoBuyQty,
    int? bogoGetQty,
    double? bogoGetDiscountPercent,
    double? comboPrice,
    List<Map<String, dynamic>> tiered = const [],
    DateTime? startDate,
    DateTime? endDate,
    List<int>? daysOfWeek,
    String? timeStart,
    String? timeEnd,
    bool requiresManagerApproval = false,
    double? approvalThresholdAmount,
  }) {
    _db.execute(
      'UPDATE promotions SET name=?, type=?, active=?, scope_type=?, scope_item_ids=?, scope_category=?, '
      'exclude_item_ids=?, percent_value=?, flat_amount=?, max_discount_cap=?, min_spend_amount=?, '
      'bogo_buy_qty=?, bogo_get_qty=?, bogo_get_discount_percent=?, combo_price=?, tiered_json=?, '
      'start_date=?, end_date=?, days_of_week=?, time_start=?, time_end=?, requires_manager_approval=?, '
      'approval_threshold_amount=? WHERE id=?',
      [
        name.trim(),
        type,
        active ? 1 : 0,
        scopeType,
        scopeItemIds.isEmpty ? null : jsonEncode(scopeItemIds),
        scopeCategory,
        excludeItemIds.isEmpty ? null : jsonEncode(excludeItemIds),
        percentValue,
        flatAmount,
        maxDiscountCap,
        minSpendAmount,
        bogoBuyQty,
        bogoGetQty,
        bogoGetDiscountPercent,
        comboPrice,
        tiered.isEmpty ? null : jsonEncode(tiered),
        startDate?.toIso8601String(),
        endDate?.toIso8601String(),
        daysOfWeek == null ? null : jsonEncode(daysOfWeek),
        timeStart,
        timeEnd,
        requiresManagerApproval ? 1 : 0,
        approvalThresholdAmount,
        id,
      ],
    );
    if (_db.updatedRows == 0) return null;
    return getPromotion(id);
  }

  bool deletePromotion(String id) {
    _db.execute('DELETE FROM promotion_codes WHERE promotion_id = ?', [id]);
    _db.execute('DELETE FROM promotions WHERE id = ?', [id]);
    return _db.updatedRows > 0;
  }

  DbPromotionCode addPromotionCode(String promotionId, String code, {int? maxUses}) {
    final id = _uuid.v4().substring(0, 8);
    _db.execute(
      'INSERT INTO promotion_codes (id, promotion_id, code, max_uses) VALUES (?, ?, ?, ?)',
      [id, promotionId, code.trim().toUpperCase(), maxUses],
    );
    final rows = _db.select('SELECT * FROM promotion_codes WHERE id = ?', [id]);
    return DbPromotionCode._fromRow(rows.first);
  }

  bool deletePromotionCode(String codeId) {
    _db.execute('DELETE FROM promotion_codes WHERE id = ?', [codeId]);
    return _db.updatedRows > 0;
  }

  /// Case-insensitive code lookup, joined with its parent promotion. Null
  /// means the code doesn't exist at all — a code that exists but is
  /// expired/used-up/inactive is still returned so the caller can report a
  /// specific reason instead of a generic "not found".
  ({DbPromotion promotion, DbPromotionCode code})? findPromotionByCode(String code) {
    final codeRows = _db.select(
      'SELECT * FROM promotion_codes WHERE UPPER(code) = UPPER(?)',
      [code.trim()],
    );
    if (codeRows.isEmpty) return null;
    final dbCode = DbPromotionCode._fromRow(codeRows.first);
    final promotion = getPromotion(dbCode.promotionId);
    if (promotion == null) return null;
    return (promotion: promotion, code: dbCode);
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  /// Scoped to today so the shop-facing counter restarts at 1 each day
  /// instead of climbing forever — [id] (the real primary key) is what
  /// every other query/route actually identifies an order by.
  int _nextOrderNumber() {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = _db.select(
      'SELECT MAX(order_number) AS m FROM orders WHERE DATE(created_at) = ?',
      [today],
    );
    final max = rows.first['m'] as int?;
    return (max ?? 0) + 1;
  }

  /// [promotions] is the client-computed list of promotions that applied to
  /// this cart (see `PromotionService.evaluate` client-side) — same trust
  /// model as [items]' prices: the client is already authoritative for
  /// pricing, promotions are just another input to numbers it already sent.
  /// Each entry needs `promotionId`, `discountAmount`, optionally `codeUsed`
  /// and `approvedByUserId`.
  DbOrder createOrder({
    required String paymentMethod,
    double? amountPaid,
    required List<Map<String, dynamic>> items,
    List<Map<String, dynamic>> promotions = const [],
    int? createdByUserId,
    String? createdByName,
  }) {
    final orderNumber = _nextOrderNumber();
    final now = DateTime.now().toIso8601String();
    final total = items.fold<double>(
      0,
      (s, i) => s + ((i['price'] as num).toDouble() * (i['quantity'] as int)),
    );
    final discountTotal = promotions.fold<double>(
      0,
      (s, p) => s + (p['discountAmount'] as num).toDouble(),
    );

    _db.execute(
      'INSERT INTO orders (order_number, created_at, payment_method, amount_paid, total, status, discount_total, '
      'created_by_user_id, created_by_name) '
      "VALUES (?, ?, ?, ?, ?, 'pending', ?, ?, ?)",
      [orderNumber, now, paymentMethod, amountPaid, total, discountTotal, createdByUserId, createdByName],
    );
    final orderId = _db.lastInsertRowId;

    for (final item in items) {
      _db.execute(
        'INSERT INTO order_items '
        '(order_id, menu_item_id, menu_item_name, menu_item_category, price, quantity, sweetness, menu_item_name_th, discount_amount) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          orderId,
          item['menuItemId'],
          item['menuItemName'],
          item['menuItemCategory'],
          (item['price'] as num).toDouble(),
          item['quantity'],
          item['sweetness'],
          item['menuItemNameTh'],
          (item['discountAmount'] as num?)?.toDouble() ?? 0,
        ],
      );
    }

    for (final promo in promotions) {
      _db.execute(
        'INSERT INTO order_promotions (order_id, promotion_id, code_used, discount_amount, approved_by_user_id) '
        'VALUES (?, ?, ?, ?, ?)',
        [
          orderId,
          promo['promotionId'],
          promo['codeUsed'],
          (promo['discountAmount'] as num).toDouble(),
          promo['approvedByUserId'],
        ],
      );
      final codeUsed = promo['codeUsed'] as String?;
      if (codeUsed != null) {
        _db.execute(
          'UPDATE promotion_codes SET used_count = used_count + 1 '
          'WHERE promotion_id = ? AND UPPER(code) = UPPER(?)',
          [promo['promotionId'], codeUsed],
        );
      }
    }

    return _buildOrder(orderId, orderNumber, now, paymentMethod, amountPaid, total, 'pending', null, discountTotal,
        createdByUserId, createdByName);
  }

  DbOrder _buildOrder(
    int id,
    int orderNumber,
    String createdAt,
    String paymentMethod,
    double? amountPaid,
    double total,
    String status,
    String? cancelReason,
    double discountTotal,
    int? createdByUserId,
    String? createdByName,
  ) {
    final itemRows = _db.select(
      'SELECT * FROM order_items WHERE order_id = ?',
      [id],
    );
    final promoRows = _db.select(
      'SELECT op.promotion_id, p.name, op.discount_amount, op.code_used, op.approved_by_user_id '
      'FROM order_promotions op JOIN promotions p ON p.id = op.promotion_id '
      'WHERE op.order_id = ?',
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
      cancelReason: cancelReason,
      items: itemRows.map(DbOrderItem._fromRow).toList(),
      discountTotal: discountTotal,
      appliedPromotions: promoRows
          .map((r) => DbAppliedPromotion(
                promotionId: r['promotion_id'] as String,
                name: r['name'] as String,
                discountAmount: (r['discount_amount'] as num).toDouble(),
                codeUsed: r['code_used'] as String?,
                approvedByUserId: r['approved_by_user_id'] as int?,
              ))
          .toList(),
      createdByUserId: createdByUserId,
      createdByName: createdByName,
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
        row['cancel_reason'] as String?,
        (row['discount_total'] as num?)?.toDouble() ?? 0,
        row['created_by_user_id'] as int?,
        row['created_by_name'] as String?,
      );

  List<DbOrder> getOrders({String? date}) {
    final buffer = StringBuffer(
      'SELECT o.id, o.order_number, o.created_at, o.payment_method, '
      'o.amount_paid, o.total, o.status, o.cancel_reason, o.discount_total, '
      'o.created_by_user_id, o.created_by_name FROM orders o',
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

  /// Orders still in the kitchen pipeline (not completed or cancelled), oldest first.
  List<DbOrder> getActiveOrders() {
    final rows = _db.select(
      "SELECT id, order_number, created_at, payment_method, amount_paid, total, status, cancel_reason, discount_total, "
      "created_by_user_id, created_by_name "
      "FROM orders WHERE status NOT IN ('completed', 'cancelled') ORDER BY id ASC",
    );
    return rows.map(_rowToOrder).toList();
  }

  DbOrder? getOrderById(int id) {
    final rows = _db.select(
      'SELECT id, order_number, created_at, payment_method, amount_paid, total, status, cancel_reason, discount_total, '
      'created_by_user_id, created_by_name '
      'FROM orders WHERE id = ?',
      [id],
    );
    if (rows.isEmpty) return null;
    return _rowToOrder(rows.first);
  }

  DbOrder? updateOrderStatus(int id, String status, {String? reason}) {
    if (status == 'cancelled') {
      _db.execute('UPDATE orders SET status = ?, cancel_reason = ? WHERE id = ?', [status, reason, id]);
    } else {
      _db.execute('UPDATE orders SET status = ? WHERE id = ?', [status, id]);
    }
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
    if (order.status == 'completed' || order.status == 'cancelled') return order;

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
    final where = date != null
        ? "WHERE status != 'cancelled' AND DATE(created_at) = '$date'"
        : "WHERE status != 'cancelled'";
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
