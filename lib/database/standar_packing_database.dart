import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 🔹 Model class Barang
class BarangModel {
  final int? id;
  final String itemcode;
  final String description;
  final String colorcode;
  final String color;
  final int qtyperstore;
  final String kg_pallet;
  final String std_pallet;

  BarangModel({
    this.id,
    required this.itemcode,
    required this.description,
    required this.colorcode,
    required this.color,
    required this.qtyperstore,
    required this.kg_pallet,
    required this.std_pallet,
  });

  /// Convert object ke Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemcode': itemcode,
      'description': description,
      'color_code': colorcode,
      'color': color,
      'qty_perstore': qtyperstore,
      'kg_pallet': kg_pallet,
      'std_pallet': std_pallet,
    };
  }

  /// Convert Map ke object
  factory BarangModel.fromMap(Map<String, dynamic> map) {
    return BarangModel(
      id: map['id'],
      itemcode: map['itemcode'],
      description: map['description'],
      colorcode: map['color_code'],
      color: map['color'],
      qtyperstore: map['qty_perstore'],
      kg_pallet: map['kg_pallet'],
      std_pallet: map['std_pallet'],
    );
  }
}

/// 🔹 Helper class untuk Database SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("barang.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Buat tabel sesuai dengan model Barang
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE barang(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itemcode TEXT NOT NULL,
        description TEXT,
        color_code TEXT,
        color TEXT,
        qty_perstore INTEGER,
        kg_pallet TEXT,
        std_pallet TEXT
      )
    ''');
  }

  /// Hapus tabel lama dan buat baru saat upgrade versi DB
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS barang');
    await _createDB(db, newVersion);
  }

  /// CRUD
  Future<int> insertBarang(BarangModel barang) async {
    final db = await instance.database;
    return await db.insert("barang", barang.toMap());
  }

  Future<List<BarangModel>> getBarang() async {
    final db = await instance.database;
    final result = await db.query("barang");
    return result.map((map) => BarangModel.fromMap(map)).toList();
  }

  Future<int> updateBarang(BarangModel barang) async {
    final db = await instance.database;
    return await db.update(
      "barang",
      barang.toMap(),
      where: "id = ?",
      whereArgs: [barang.id],
    );
  }

  Future<int> deleteBarang(int id) async {
    final db = await instance.database;
    return await db.delete(
      "barang",
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
