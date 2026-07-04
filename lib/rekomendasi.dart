import 'package:flutter/material.dart';
import 'models/penjualan_model.dart';
import 'models/rekomendasi_model.dart';
import 'services/firestore_service.dart';
import 'services/penjualan_service.dart';

class RekomendasiPage extends StatefulWidget {
  const RekomendasiPage({super.key});

  @override
  State<RekomendasiPage> createState() => _RekomendasiPageState();
}

class _RekomendasiPageState extends State<RekomendasiPage> {
  bool _isLoading = false;
  String? _errorMessage;
  List<AnalisisTren> _analisisList = [];

  Future<void> _analisisOtomatis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _analisisList.clear();
    });

    try {
      final obatNames = await PenjualanService.getAllObatNames();

      if (obatNames.isEmpty) {
        setState(() {
          _errorMessage = 'Belum ada data penjualan. Catat penjualan terlebih dahulu.';
          _isLoading = false;
        });
        return;
      }

      List<AnalisisTren> hasil = [];
      for (String namaObat in obatNames) {
        if (namaObat.isEmpty) continue;
        final analisis = await PenjualanService.analyzeObat(namaObat);
        hasil.add(analisis);
      }

      hasil.sort((a, b) {
        final aPriority = _getRecommendationPriority(a.getRekomendasi());
        final bPriority = _getRecommendationPriority(b.getRekomendasi());
        return aPriority.compareTo(bPriority);
      });

      setState(() {
        _analisisList = hasil;
        _isLoading = false;
      });

      await FirestoreService.simpanRekomendasi(
        restock: hasil
            .where((a) => a.getRekomendasi().startsWith('Beli'))
            .map((a) => RestockItem(
              nama: a.namaObat,
              saran: 'Beli',
              jumlah: _calculateRestockAmount(a),
              alasan: a.getRekomendasi(),
            ))
            .toList(),
        tidakRestock: hasil
            .where((a) => !a.getRekomendasi().startsWith('Beli'))
            .map((a) => TidakRestockItem(
              nama: a.namaObat,
              alasan: a.getRekomendasi(),
            ))
            .toList(),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  int _getRecommendationPriority(String rekomendasi) {
    if (rekomendasi.startsWith('Beli')) return 0;
    if (rekomendasi.startsWith('Jual')) return 1;
    return 2;
  }

  int _calculateRestockAmount(AnalisisTren analisis) {
    if (analisis.tren > 0.2) return 50;
    if (analisis.tren > 0) return 30;
    return 20;
  }

  Widget _buildStatusBadge(String rekomendasi) {
    Color bgColor;
    IconData icon;

    if (rekomendasi.startsWith('Beli')) {
      bgColor = Colors.green;
      icon = Icons.shopping_cart;
    } else if (rekomendasi.startsWith('Jual')) {
      bgColor = Colors.orange;
      icon = Icons.sell;
    } else {
      bgColor = Colors.blue;
      icon = Icons.pause_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            rekomendasi.split(' - ')[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Cerdas (FEFO)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Smart Rekomendasi berdasarkan TREN PENJUALAN, STOK, dan FEFO (First Expiry First Out)',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _analisisOtomatis,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.auto_graph),
              label: Text(_isLoading ? 'Menganalisis...' : 'Jalankan Analisis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            if (!_isLoading && _analisisList.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.info, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tekan tombol di atas untuk memulai analisis.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            if (_analisisList.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _analisisList.length,
                  itemBuilder: (context, index) {
                    final analisis = _analisisList[index];
                    final rekomendasi = analisis.getRekomendasi();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      child: ExpansionTile(
                        leading: _buildStatusBadge(rekomendasi),
                        title: Text(analisis.namaObat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                analisis.tren > 0.2 ? Icons.trending_up : analisis.tren < -0.2 ? Icons.trending_down : Icons.trending_flat,
                                size: 16,
                                color: analisis.tren > 0.2 ? Colors.green : analisis.tren < -0.2 ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${analisis.getTrenLabel()} • Stok: ${analisis.stokTerkini}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow('Penjualan Bulan Ini:', '${analisis.totalPenjualanBulanIni} unit'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Penjualan Bulan Lalu:', '${analisis.totalPenjualanBulanLalu} unit'),
                                const SizedBox(height: 10),
                                _buildInfoRow('Stok Terkini:', '${analisis.stokTerkini} unit',
                                    color: analisis.stokTerkini < 10 ? Colors.red : Colors.green),
                                const SizedBox(height: 10),
                                _buildInfoRow('Tren Perubahan:', '${(analisis.tren * 100).toStringAsFixed(0)}%',
                                    color: analisis.tren > 0 ? Colors.green : Colors.red),
                                const Divider(height: 20),
                                const Text('💡 REKOMENDASI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber),
                                  ),
                                  child: Text(rekomendasi, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
      ],
    );
  }
}

