import 'dart:convert';
import 'package:flutter/material.dart';
import 'openai_service.dart';
import 'models/rekomendasi_model.dart';
import 'package:ocr/services/firestore_service.dart';

/// 1️⃣ MODEL DATA (MOCK DATABASE)
class DataObat {
  String nama;
  int terjual;
  int sisaStok;
  String tren;

  DataObat({
    required this.nama,
    required this.terjual,
    required this.sisaStok,
    required this.tren,
  });
}

class RekomendasiPage extends StatefulWidget {
  const RekomendasiPage({super.key});

  @override
  State<RekomendasiPage> createState() => _RekomendasiPageState();
}

class _RekomendasiPageState extends State<RekomendasiPage> {
  bool _isLoading = false;
  String? _errorMessage;

  /// HASIL PARSING
  List<RestockItem> _restockList = [];
  List<TidakRestockItem> _tidakRestockList = [];

  /// 2️⃣ MOCK DATA PENJUALAN
  final List<DataObat> _databasePenjualan = [
    DataObat(
      nama: "Paracetamol 500mg",
      terjual: 150,
      sisaStok: 10,
      tren: "Naik Drastis",
    ),
    DataObat(nama: "Amoxicillin", terjual: 20, sisaStok: 85, tren: "Turun"),
    DataObat(
      nama: "Vitamin C IPI",
      terjual: 200,
      sisaStok: 5,
      tren: "Stabil Tinggi",
    ),
    DataObat(nama: "Obat Batuk Komix", terjual: 45, sisaStok: 12, tren: "Naik"),
    DataObat(
      nama: "Minyak Kayu Putih",
      terjual: 10,
      sisaStok: 50,
      tren: "Rendah",
    ),
  ];

  // ==================================================
  // 🔒 VALIDASI STRUKTUR JSON (ANTI ERROR)
  // ==================================================
  bool _isValidRekomendasiJson(Map<String, dynamic> json) {
    if (!json.containsKey('restock')) return false;
    if (!json.containsKey('tidak_restock')) return false;
    if (json['restock'] is! List) return false;
    if (json['tidak_restock'] is! List) return false;
    return true;
  }

  // ==================================================
  // 3️⃣ PROSES ANALISIS + PARSING JSON (AMAN)
  // ==================================================
  Future<void> _analisisOtomatis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _restockList.clear();
      _tidakRestockList.clear();
    });

    // 1️⃣ Gabungkan data penjualan → string
    String dataUntukAI = "";
    for (var obat in _databasePenjualan) {
      dataUntukAI +=
      "- ${obat.nama}: Terjual ${obat.terjual}, "
          "Sisa Stok ${obat.sisaStok}, Tren ${obat.tren}\n";
    }

    try {
      // 2️⃣ Panggil AI
      final hasilAI = await OpenAIService.generateRekomendasi(dataUntukAI);

      // debugPrint("RAW AI JSON:\n$hasilAI");

      // 3️⃣ Decode JSON
      final Map<String, dynamic> decoded = jsonDecode(hasilAI);

      if (!_isValidRekomendasiJson(decoded)) {
        throw Exception("Struktur JSON tidak valid");
      }

      final List restockJson = decoded['restock'];
      final List tidakRestockJson = decoded['tidak_restock'];

      final List<RestockItem> restockParsed =
      restockJson.map((e) => RestockItem.fromJson(e)).toList();

      final List<TidakRestockItem> tidakRestockParsed =
      tidakRestockJson.map((e) => TidakRestockItem.fromJson(e)).toList();

      // 4️⃣ Update UI
      setState(() {
        _restockList = restockParsed;
        _tidakRestockList = tidakRestockParsed;
        _isLoading = false;
      });

      // 5️⃣ Simpan ke Firebase (DI LUAR setState)
      await FirestoreService.simpanRekomendasi(
        restock: restockParsed,
        tidakRestock: tidakRestockParsed,
      );
    } catch (e) {
      setState(() {
        _errorMessage =
        "AI gagal menghasilkan rekomendasi yang valid. Silakan coba lagi.";
        _isLoading = false;
      });
    }
  }


  // ==================================================
  // 4️⃣ UI
  // ==================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Restock System"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Data Penjualan Bulan Ini (Mock DB):",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            /// LIST DATA PENJUALAN
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _databasePenjualan.length,
                itemBuilder: (context, index) {
                  final data = _databasePenjualan[index];
                  return ListTile(
                    leading:
                    const Icon(Icons.medication, color: Colors.blue),
                    title: Text(data.nama),
                    subtitle: Text(
                      "Terjual: ${data.terjual} | "
                          "Sisa: ${data.sisaStok} | "
                          "Tren: ${data.tren}",
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analisisOtomatis,
              icon: const Icon(Icons.auto_graph),
              label: Text(
                _isLoading
                    ? "Memproses Data..."
                    : "Generate Saran Pembelian (AI)",
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),

            const SizedBox(height: 10),
            const Divider(),

            /// ERROR MESSAGE
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            /// EMPTY STATE
            if (!_isLoading &&
                _errorMessage == null &&
                _restockList.isEmpty &&
                _tidakRestockList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Belum ada rekomendasi yang ditampilkan.",
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),

            /// HASIL RESTOCK
            if (_restockList.isNotEmpty) ...[
              const Text(
                "Perlu Dibeli Ulang",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._restockList.map(
                    (item) => Card(
                  color: Colors.green[50],
                  child: ListTile(
                    leading: const Icon(Icons.add_shopping_cart,
                        color: Colors.green),
                    title: Text(item.nama),
                    subtitle: Text(item.alasan),
                    trailing: Text(
                      "+${item.jumlah}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            /// HASIL TIDAK RESTOCK
            if (_tidakRestockList.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                "Tidak Perlu Dibeli",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._tidakRestockList.map(
                    (item) => Card(
                  color: Colors.red[50],
                  child: ListTile(
                    leading:
                    const Icon(Icons.remove_circle, color: Colors.red),
                    title: Text(item.nama),
                    subtitle: Text(item.alasan),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
