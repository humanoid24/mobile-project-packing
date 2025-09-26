import 'package:flutter/material.dart';
import 'package:project_packing/database/deadstock_customed_furniture.dart'; // sesuaikan path file database

class CustomedFurnitureTab extends StatefulWidget {
  const CustomedFurnitureTab({super.key});

  @override
  State<CustomedFurnitureTab> createState() => _CustomedFurnitureTabState();
}

class _CustomedFurnitureTabState extends State<CustomedFurnitureTab> {
  List<Barang_Customed_FurnitureModel> furnitureList = [];
  String searchQuery = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshFurniture();
  }

  Future refreshFurniture() async {
    setState(() => isLoading = true);
    furnitureList = await DatabaseCustomed_Furniture.instance.getFurniture();
    setState(() => isLoading = false);
  }

  int calculateCrossAxisCount(double width) {
    if (width < 600) return 1;
    if (width < 1200) return 2;
    return 3;
  }

  Future showFurnitureForm({Barang_Customed_FurnitureModel? item}) async {
    final namaController = TextEditingController(text: item?.nama_item ?? '');
    final ageController =
    TextEditingController(text: item?.age.toString() ?? '');
    final qtyController =
    TextEditingController(text: item?.qty.toString() ?? '');
    final locationController =
    TextEditingController(text: item?.location ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? "Tambah Furniture" : "Edit Furniture"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: "Nama Item"),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newItem = Barang_Customed_FurnitureModel(
                id: item?.id,
                nama_item: namaController.text,
                age: int.tryParse(ageController.text) ?? 0,
                qty: int.tryParse(qtyController.text) ?? 0,
                location: locationController.text,
              );

              if (item == null) {
                await DatabaseCustomed_Furniture.instance
                    .insertCustomedFurniture(newItem);
              } else {
                await DatabaseCustomed_Furniture.instance
                    .updateFurniture(newItem);
              }
              Navigator.pop(context);
              refreshFurniture();
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
    List<Barang_Customed_FurnitureModel> filteredList =
    furnitureList.where((customed) {
      final matchesSearch =
      customed.nama_item.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Padding(
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
                onPressed: () async {
                  await showFurnitureForm();
                },
                icon: const Icon(Icons.add),
                label: const Text("Tambah"),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Grid view
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                ? const Center(child: Text("Belum ada data"))
                : GridView.builder(
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: calculateCrossAxisCount(screenWidth),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3 / 2,
              ),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.nama_item,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text("Age: ${item.age}"),
                        Text("Quantity: ${item.qty}"),
                        Text("Location: ${item.location}"),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () async {
                                await showFurnitureForm(item: item);
                                refreshFurniture();
                              },
                              icon: const Icon(Icons.edit,
                                  color: Colors.blue),
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirm =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                        "Konfirmasi Hapus"),
                                    content: Text(
                                        "Apakah Anda yakin ingin menghapus '${item.nama_item}'?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, false),
                                        child: const Text("Batal"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context, true),
                                        child: const Text("Ya"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await DatabaseCustomed_Furniture
                                      .instance
                                      .deleteFurniture(item.id!);
                                  refreshFurniture();
                                }
                              },
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
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
    );
  }
}
