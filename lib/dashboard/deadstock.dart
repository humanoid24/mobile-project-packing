import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../tabs/CustomedFurnitureTab.dart';
import '../tabs/CustomedProductionTab.dart';
import '../tabs/DoorTab.dart';
import '../tabs/RetailEquipmentTab.dart';
import '../tabs/ShopfittingTab.dart';
import '../tabs/StorageSystemTab.dart';

class Deadstock extends StatefulWidget {
  const Deadstock({super.key});

  @override
  State<Deadstock> createState() => _DeadstockState();
}

class _DeadstockState extends State<Deadstock> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController( // ✅ harus ada ini
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deadstock'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Customed Furniture'),
              Tab(text: 'Customed Production'),
              Tab(text: 'Door'),
              Tab(text: 'Retail Equipment'),
              Tab(text: 'Shopfitting'),
              Tab(text: 'Storage System'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CustomedFurnitureTab(),
            Customedproductiontab(),
            Doortab(),
            Retailequipmenttab(),
            Shopfittingtab(),
            Storagesystemtab(),
          ],
        ),
      ),
    );
  }
}
