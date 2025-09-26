import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Barang_Customed_FurnitureModel
{
  final int? id;
  final String nama_item;
  final int age;
  final int qty;
  final String location;


    Barang_Customed_FurnitureModel({
      this.id,
      required this.nama_item,
      required this.age,
      required this.qty,
      required this.location
  });

    Map<String, dynamic> toMap(){
      return{
        'id': id,
        'nama_item': nama_item,
        'age': age,
        'qty': qty,
        'location': location
      };
    }

    factory Barang_Customed_FurnitureModel.fromMap(Map<String, dynamic> map)
    {
      return Barang_Customed_FurnitureModel(
        id: map['id'],
        nama_item: map['nama_item'],
        age: map['age'],
        qty: map['qty'],
        location: map['location']
      );
    }
}

class DatabaseCustomed_Furniture
{
  static final DatabaseCustomed_Furniture instance = DatabaseCustomed_Furniture._init();
  static Database? _database;

  DatabaseCustomed_Furniture._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("customed_furniture.db");
    return _database!;
  }

  /// Inisialisasi database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Buat tabel barang
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customed_furniture(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_item TEXT,
        age INTEGER,
        qty INTEGER,
        location TEXT
      )
    ''');
  }

  Future<int> insertCustomedFurniture(Barang_Customed_FurnitureModel Furniture)
  async {
    final db = await instance.database;
    return await db.insert('customed_furniture', Furniture.toMap());
  }

  /// Ambil semua barang
  Future<List<Barang_Customed_FurnitureModel>> getFurniture() async {
    final db = await instance.database;
    final result = await db.query("customed_furniture");
    return result.map((map) => Barang_Customed_FurnitureModel.fromMap(map)).toList();
  }

  /// Update barang
  Future<int> updateFurniture(Barang_Customed_FurnitureModel Furniture) async {
    final db = await instance.database;
    return await db.update(
      "customed_furniture",
      Furniture.toMap(),
      where: "id = ?",
      whereArgs: [Furniture.id],
    );
  }

  /// Hapus barang
  Future<int> deleteFurniture(int id) async {
    final db = await instance.database;
    return await db.delete(
      "customed_furniture",
      where: "id = ?",
      whereArgs: [id],
    );
  }
}