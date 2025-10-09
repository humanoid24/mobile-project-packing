import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 🔹 Model class Barang
class BarangModel {
  final int? id; // null saat insert
  final String nama;
  final String kategori;
  final String jenisKemasan;
  final int panjang;
  final int lebar;
  final int tinggi;
  final String satuanMeter;
  final int berat;
  final String satuanBerat;
  final String deskripsi;

  BarangModel({
    this.id,
    required this.nama,
    required this.kategori,
    required this.jenisKemasan,
    required this.panjang,
    required this.lebar,
    required this.tinggi,
    required this.satuanMeter,
    required this.berat,
    required this.satuanBerat,
    required this.deskripsi,
  });

  /// Convert object ke Map (untuk insert/update ke SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'jenis_kemasan': jenisKemasan,
      'panjang': panjang,
      'lebar': lebar,
      'tinggi': tinggi,
      'satuan_meter': satuanMeter,
      'berat': berat,
      'satuan_berat': satuanBerat,
      'deskripsi': deskripsi,
    };
  }

  /// Convert Map (dari SQLite) ke object
  factory BarangModel.fromMap(Map<String, dynamic> map) {
    return BarangModel(
      id: map['id'],
      nama: map['nama'],
      kategori: map['kategori'],
      jenisKemasan: map['jenis_kemasan'],
      panjang: map['panjang'],
      lebar: map['lebar'],
      tinggi: map['tinggi'],
      satuanMeter: map['satuan_meter'],
      berat: map['berat'],
      satuanBerat: map['satuan_berat'],
      deskripsi: map['deskripsi'],
    );
  }
}

/// 🔹 Helper class untuk Database SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  /// Ambil database (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("barang.db");
    return _database!;
  }

  /// Inisialisasi database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // ⬅️ ubah versi database agar migrate ulang
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Buat tabel barang
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE barang(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT,
        kategori TEXT,
        jenis_kemasan TEXT,
        panjang INTEGER,
        lebar INTEGER,
        tinggi INTEGER,
        satuan_meter TEXT,
        berat INTEGER,
        satuan_berat TEXT,
        deskripsi TEXT
      )
    ''');
  }

  /// Handle upgrade versi DB (hapus tabel lama kalau ada)
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS barang');
    await _createDB(db, newVersion);
  }

  /// Tambah barang
  Future<int> insertBarang(BarangModel barang) async {
    final db = await instance.database;
    return await db.insert("barang", barang.toMap());
  }

  /// Ambil semua barang
  Future<List<BarangModel>> getBarang() async {
    final db = await instance.database;
    final result = await db.query("barang");
    return result.map((map) => BarangModel.fromMap(map)).toList();
  }

  /// Update barang
  Future<int> updateBarang(BarangModel barang) async {
    final db = await instance.database;
    return await db.update(
      "barang",
      barang.toMap(),
      where: "id = ?",
      whereArgs: [barang.id],
    );
  }

  /// Hapus barang
  Future<int> deleteBarang(int id) async {
    final db = await instance.database;
    return await db.delete(
      "barang",
      where: "id = ?",
      whereArgs: [id],
    );
  }
}
