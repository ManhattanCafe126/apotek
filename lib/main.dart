import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ocr/firebase_options.dart';
import 'riset_mlkit.dart';
import 'rekomendasi.dart';
import 'histori_rekomendasi.dart';
import 'grafik_bulanan_page.dart';
import 'grafik_compare.dart';

void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riset Skripsi Apotek',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HalamanMenuUtama(),
    );
  }
}

class HalamanMenuUtama extends StatelessWidget {
  const HalamanMenuUtama({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menu Riset Skripsi"),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Pilih Fitur Riset:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // TOMBOL 1: KE FITUR OCR & BARCODE (File riset_mlkit.dart)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RisetMLKitPage()),
                );
              },
              icon: const Icon(Icons.camera_alt, size: 30),
              label: const Text("Scan Stok (OCR & Barcode)", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // TOMBOL 2: KE FITUR GEMINI (File fitur_rekomendasi.x)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RekomendasiPage()),
                );
              },
              icon: const Icon(Icons.psychology, size: 30),
              label: const Text("Rekomendasi Cerdas (AI)", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoriRekomendasiPage(),
                  ),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text("Histori Rekomendasi"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GrafikBulananPage()),
              ),
              child: const Text("Grafik per Bulan"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.compare),
              label: const Text("Perbandingan Tahunan"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GrafikComparePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}