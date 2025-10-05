import 'package:flutter/material.dart';
import 'package:project_packing/dashboard/deadstock.dart';
import 'package:project_packing/dashboard/skupackinglayout.dart';
import 'package:project_packing/dashboard/standarpacking.dart';
import 'package:project_packing/dashboard/unloadingonstatus.dart';

class Pilihsistem extends StatefulWidget {
  const Pilihsistem({super.key});

  @override
  State<Pilihsistem> createState() => _PilihsistemState();
}

class _PilihsistemState extends State<Pilihsistem> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pilih Sistem"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,

      ),
      body: Center(
        child: SizedBox(
          width: 350,
          height: 500,
          child: Card(
            color: const Color(0xFF001F3F),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    child: const SizedBox(
                      height: 50,
                      width: 250,
                      child: Center(
                        child: Text(
                          "Logistic Database",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _Menu("Standar Packing", Colors.white, Standarpacking()),
                        _Menu("Deadstock > 210 Days Status", Colors.white, Deadstock()),
                        _Menu("SKU Packing Layout", Colors.white, Skupackinglayout()),
                        _Menu("Unloading Lane Status", Colors.white, Unloadingonstatus()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _Menu(String title, Color color, Widget nextPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
        );
      },
      child: Card(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

