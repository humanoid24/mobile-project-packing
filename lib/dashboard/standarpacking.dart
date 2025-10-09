import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:project_packing/database/standar_packing_database.dart'; // berisi DatabaseHelper + BarangModel
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
  String? selectedKategori;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

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

      // Ambil sheet pertama
      final table = decoder.tables.values.first;

      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is num) return value.toInt();
        return int.tryParse(value.toString().replaceAll(RegExp(r'[^0-9\-]'), '')) ?? 0;
      }

      int successCount = 0;
      for (int i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;

        final barang = BarangModel(
          nama: row.length > 1 ? row[1]?.toString() ?? "" : "",
          kategori: row.length > 2 ? row[2]?.toString() ?? "" : "",
          jenisKemasan: row.length > 3 ? row[3]?.toString() ?? "" : "",
          panjang: row.length > 4 ? parseInt(row[4]) : 0,
          lebar: row.length > 5 ? parseInt(row[5]) : 0,
          tinggi: row.length > 6 ? parseInt(row[6]) : 0,
          satuanMeter: row.length > 7 ? row[7]?.toString() ?? "" : "",
          berat: row.length > 8 ? parseInt(row[8]) : 0,
          satuanBerat: row.length > 9 ? row[9]?.toString() ?? "" : "",
          deskripsi: row.length > 10 ? row[10]?.toString() ?? "" : "",
        );

        await DatabaseHelper.instance.insertBarang(barang);
        successCount++;
      }

      // Ambil semua data setelah import
      final allData = await DatabaseHelper.instance.getBarang();
      print("📦 Jumlah data di DB setelah import: ${allData.length}");
      for (var b in allData) {
        print("➡️ ${b.nama} (${b.kategori})");
      }

      await _loadBarang();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Import berhasil ($successCount data ditambahkan)")),
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
    setState(() {
      barangList = data;
    });
  }

  Future<void> _exportToExcel() async {
    // Ambil data dari database
    final data = await DatabaseHelper.instance.getBarang();

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diekspor")),
      );
      return;
    }

    // Buat workbook Excel
    var excel = Excel.createExcel();
    Sheet sheet = excel['Standar Packing'];

    // Tambahkan header
    sheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Nama'),
      TextCellValue('Kategori'),
      TextCellValue('Jenis Kemasan'),
      TextCellValue('Panjang'),
      TextCellValue('Lebar'),
      TextCellValue('Tinggi'),
      TextCellValue('Satuan Meter'),
      TextCellValue('Berat'),
      TextCellValue('Satuan Berat'),
      TextCellValue('Deskripsi'),
    ]);


    // Tambahkan data ke sheet
    for (var b in data) {
      sheet.appendRow([
        IntCellValue(b.id ?? 0),
        TextCellValue(b.nama),
        TextCellValue(b.kategori),
        TextCellValue(b.jenisKemasan),
        IntCellValue(b.panjang),
        IntCellValue(b.lebar),
        IntCellValue(b.tinggi),
        TextCellValue(b.satuanMeter),
        IntCellValue(b.berat),
        TextCellValue(b.satuanBerat),
        TextCellValue(b.deskripsi),
      ]);
    }


    // Simpan ke file
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${dir.path}/standar_packing_$timestamp.xlsx';
    final bytes = excel.encode();

    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
    }

    // Notifikasi ke user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Data berhasil diekspor ke $filePath")),
    );
    // setelah file disimpan
    await OpenFilex.open(filePath);
  }

  /// Responsive grid
  int calculateCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 1200) return 2;
    return 3;
  }

  /// Dialog tambah/edit barang
  void _showInputDialog({BarangModel? barang}) {
    final TextEditingController namaC =
    TextEditingController(text: barang?.nama ?? "");
    final TextEditingController kategoriC =
    TextEditingController(text: barang?.kategori ?? "");
    final TextEditingController jenisKemasanC =
    TextEditingController(text: barang?.jenisKemasan ?? "");
    final TextEditingController panjangC =
    TextEditingController(text: barang?.panjang.toString() ?? "");
    final TextEditingController lebarC =
    TextEditingController(text: barang?.lebar.toString() ?? "");
    final TextEditingController tinggiC =
    TextEditingController(text: barang?.tinggi.toString() ?? "");

    final TextEditingController satuanMeterC =
    TextEditingController(text: barang?.satuanMeter ?? "");


    final TextEditingController beratC =
    TextEditingController(text: barang?.berat.toString() ?? "");
    final TextEditingController satuanBeratC =
    TextEditingController(text: barang?.satuanBerat ?? "");
    final TextEditingController deskripsiC =
    TextEditingController(text: barang?.deskripsi ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(barang == null ? "Tambah Barang" : "Edit Barang"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: namaC, decoration: const InputDecoration(labelText: "Nama")),
              TextField(controller: kategoriC, decoration: const InputDecoration(labelText: "Kategori")),
              TextField(controller: jenisKemasanC, decoration: const InputDecoration(labelText: "Jenis Kemasan")),
              TextField(controller: panjangC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Panjang")),
              TextField(controller: lebarC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Lebar")),
              TextField(controller: tinggiC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Tinggi")),
              TextField(controller: satuanMeterC, decoration: const InputDecoration(labelText: "Satuan Meter")),
              TextField(controller: beratC, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Berat")),
              TextField(controller: satuanBeratC, decoration: const InputDecoration(labelText: "Satuan Berat")),
              TextField(controller: deskripsiC, decoration: const InputDecoration(labelText: "Deskripsi")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (namaC.text.isNotEmpty && kategoriC.text.isNotEmpty) {
                final newBarang = BarangModel(
                  id: barang?.id, // kalau edit, id diisi
                  nama: namaC.text,
                  kategori: kategoriC.text,
                  jenisKemasan: jenisKemasanC.text,
                  panjang: int.tryParse(panjangC.text) ?? 0,
                  lebar: int.tryParse(lebarC.text) ?? 0,
                  tinggi: int.tryParse(tinggiC.text) ?? 0,
                  satuanMeter: satuanMeterC.text,
                  berat: int.tryParse(beratC.text) ?? 0,
                  satuanBerat: satuanBeratC.text,
                  deskripsi: deskripsiC.text,
                );

                if (barang == null) {
                  await DatabaseHelper.instance.insertBarang(newBarang);
                } else {
                  await DatabaseHelper.instance.updateBarang(newBarang);
                }

                Navigator.pop(context);
                _loadBarang();
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    // filter pencarian
    List<BarangModel> filteredList = barangList.where((barang) {
      final matchesSearch =
      barang.nama.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesKategori =
          selectedKategori == null || barang.kategori == selectedKategori;
      return matchesSearch && matchesKategori;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard Barang"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: "Import dari Excel",
            onPressed: _importFromExcel,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export ke Excel",
            onPressed: _exportToExcel,
          ),
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
                      hintText: "Cari barang...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
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

            // Grid barang
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
                  final barang = filteredList[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(barang.nama,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Kategori: ${barang.kategori}"),
                          Text("Kemasan: ${barang.jenisKemasan}"),
                          Text("Dimensi: ${barang.panjang} x ${barang.lebar} x ${barang.tinggi} ${barang.satuanMeter}"),
                          Text("Berat: ${barang.berat} ${barang.satuanBerat}"),
                          Expanded(
                            child: Text(
                              "Deskripsi: ${barang.deskripsi}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton( onPressed: () { _showInputDialog(barang: barang); }, icon: const Icon(Icons.edit, color: Colors.blue), ),
                              IconButton(
                                onPressed: () async {
                                  // Tampilkan dialog konfirmasi
                                  final bool? confirmDelete = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Konfirmasi Hapus"),
                                      content: Text("Apakah Anda yakin ingin menghapus '${barang.nama}'?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false), // batal
                                          child: const Text("Batal"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () => Navigator.pop(context, true), // konfirmasi
                                          child: const Text("Hapus"),
                                        ),
                                      ],
                                    ),
                                  );

                                  // Kalau user pilih "Hapus"
                                  if (confirmDelete == true) {
                                    await DatabaseHelper.instance.deleteBarang(barang.id!);
                                    _loadBarang();

                                    // kasih feedback snackbar
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Barang '${barang.nama}' berhasil dihapus"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete, color: Colors.red),
                              ),

                            ],
                          )
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
