import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:project_packing/database/standar_packing_database.dart'; // BarangModel & DatabaseHelper
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

class Standarpacking extends StatefulWidget {
  const Standarpacking({super.key});

  @override
  State<Standarpacking> createState() => _StandarpackingState();
}

class _StandarpackingState extends State<Standarpacking> {
  List<BarangModel> barangList = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  /// Import dari Excel (otomatis abaikan kolom "No" kalau ada)
  Future<void> _importFromExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result == null) return;

      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final decoder = SpreadsheetDecoder.decodeBytes(bytes, update: true);

      // Ambil semua nama sheet (harusnya angka 1-31)
      final sheetNames = decoder.tables.keys.toList();

      // Sort biar urut dari kecil ke besar
      sheetNames.sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      // --- Tampilkan dialog pilih sheet angka ---
      String? selectedSheet = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Pilih Sheet (Tanggal)"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: sheetNames.length,
                itemBuilder: (context, i) {
                  return ListTile(
                    title: Text("Tanggal ${sheetNames[i]}"),
                    onTap: () => Navigator.pop(context, sheetNames[i]),
                  );
                },
              ),
            ),
          );
        },
      );

      if (selectedSheet == null) return;

      final table = decoder.tables[selectedSheet];
      if (table == null || table.rows.isEmpty) {
        throw Exception("Sheet '$selectedSheet' kosong atau tidak valid");
      }

      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is num) return value.toInt();
        return int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0;
      }

      int successCount = 0;

      // --- Import semua data dari sheet terpilih ---
      for (int i = 3; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty || row.length < 8) continue;

        final barang = BarangModel(
          description: row[2]?.toString() ?? "",
          itemcode: row[1]?.toString() ?? "",
          colorcode: row[3]?.toString() ?? "",
          color: row[4]?.toString() ?? "",
          qtyperstore: parseInt(row[5]),
          kg_pallet: row[6]?.toString() ?? "",
          std_packing: row[7]?.toString() ?? "",
        );

        await DatabaseHelper.instance.insertBarang(barang);
        successCount++;
      }

      await _loadBarang();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Berhasil import $successCount data dari sheet tanggal $selectedSheet"),
        ),
      );
    } catch (e, st) {
      print("❌ ERROR IMPORT: $e\n$st");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Gagal import: $e")),
      );
    }
  }




  /// Ambil data dari database
  Future<void> _loadBarang() async {
    final data = await DatabaseHelper.instance.getBarang();
    setState(() => barangList = data);
  }

  /// Export ke Excel
  Future<void> _exportToExcel() async {
    final data = await DatabaseHelper.instance.getBarang();

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diekspor")),
      );
      return;
    }

    var excel = Excel.createExcel();
    Sheet sheet = excel['Standar Packing'];

    // Header
    // Header (Description di depan)
    sheet.appendRow([
      TextCellValue('Description'),
      TextCellValue('Item Code'),
      TextCellValue('Color Code'),
      TextCellValue('Color'),
      TextCellValue('Qty Per Store'),
      TextCellValue('KG Pallet'),
      TextCellValue('STD Packing'),
    ]);

// Data (sesuaikan urutannya)
    for (var b in data) {
      sheet.appendRow([
        TextCellValue(b.description),
        TextCellValue(b.itemcode),
        TextCellValue(b.colorcode),
        TextCellValue(b.color),
        IntCellValue(b.qtyperstore),
        TextCellValue(b.kg_pallet),
        TextCellValue(b.std_packing),
      ]);
    }


    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${dir.path}/standar_packing_$timestamp.xlsx';
    final bytes = excel.encode();

    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Data berhasil diekspor ke $filePath")),
      );
      await OpenFilex.open(filePath);
    }
  }

  /// Dialog tambah/edit barang
  void _showInputDialog({BarangModel? barang}) {
    final itemcodeC = TextEditingController(text: barang?.itemcode ?? "");
    final descriptionC = TextEditingController(text: barang?.description ?? "");
    final colorcodeC = TextEditingController(text: barang?.colorcode ?? "");
    final colorC = TextEditingController(text: barang?.color ?? "");
    final qtyC = TextEditingController(text: barang?.qtyperstore.toString() ?? "0");
    final kgC = TextEditingController(text: barang?.kg_pallet ?? "");
    final stdC = TextEditingController(text: barang?.std_packing ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(barang == null ? "Tambah Barang" : "Edit Barang"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: itemcodeC, decoration: const InputDecoration(labelText: "Item Code")),
              TextField(controller: descriptionC, decoration: const InputDecoration(labelText: "Description")),
              TextField(controller: colorcodeC, decoration: const InputDecoration(labelText: "Color Code")),
              TextField(controller: colorC, decoration: const InputDecoration(labelText: "Color")),
              TextField(controller: qtyC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Qty Per Store")),
              TextField(controller: kgC, decoration: const InputDecoration(labelText: "KG Pallet")),
              TextField(controller: stdC, decoration: const InputDecoration(labelText: "STD Packing")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              final newBarang = BarangModel(
                id: barang?.id,
                itemcode: itemcodeC.text,
                description: descriptionC.text,
                colorcode: colorcodeC.text,
                color: colorC.text,
                qtyperstore: int.tryParse(qtyC.text) ?? 0,
                kg_pallet: kgC.text,
                std_packing: stdC.text,
              );

              if (barang == null) {
                await DatabaseHelper.instance.insertBarang(newBarang);
              } else {
                await DatabaseHelper.instance.updateBarang(newBarang);
              }

              Navigator.pop(context);
              _loadBarang();
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  /// Responsive grid
  int calculateCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 1200) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    List<BarangModel> filteredList = barangList.where((b) {
      return b.description.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Standar Packing"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.upload_file), onPressed: _importFromExcel),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportToExcel),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search + Tambah
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari item...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _showInputDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah"),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Grid data
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: calculateCrossAxisCount(screenWidth),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3 / 2,
                ),
                itemCount: filteredList.length,
                itemBuilder: (context, index) {
                  final b = filteredList[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Item Code: ${b.itemcode}"),
                          Text("Color Code: ${b.colorcode}"),
                          Text("Color: ${b.color} "),
                          Text("Qty/store: ${b.qtyperstore}"),
                          Text("KG Pallet: ${b.kg_pallet}"),
                          Text("STD Packing: ${b.std_packing}"),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(onPressed: () => _showInputDialog(barang: b), icon: const Icon(Icons.edit, color: Colors.blue)),
                              IconButton(
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Konfirmasi Hapus"),
                                      content: Text("Hapus '${b.description}'?"),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text("Hapus"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await DatabaseHelper.instance.deleteBarang(b.id!);
                                    _loadBarang();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Barang '${b.description}' dihapus"), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
