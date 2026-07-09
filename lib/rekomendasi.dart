import 'package:flutter/material.dart';
import 'models/penjualan_model.dart';
import 'models/rekomendasi_model.dart';
import 'services/firestore_service.dart';
import 'services/penjualan_service.dart';

class TampilanRekomendasiPenjualan extends StatefulWidget {
  const TampilanRekomendasiPenjualan({super.key});

  @override
  State<TampilanRekomendasiPenjualan> createState() => _TampilanRekomendasiPenjualanState();
}

class _TampilanRekomendasiPenjualanState extends State<TampilanRekomendasiPenjualan> {
  bool _isLoading = false;
  String? _errorMessage;
  List<_DrugChecklistItem> _checklistItems = [];

  Future<void> buatRekomendasi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _checklistItems.clear();
    });

    try {
      final obatNames = await LayananPenjualan.getAllObatNames();

      if (obatNames.isEmpty) {
        setState(() {
          _errorMessage = 'Belum ada data penjualan. Catat penjualan terlebih dahulu.';
          _isLoading = false;
        });
        return;
      }

      List<_DrugChecklistItem> items = [];
      for (String namaObat in obatNames) {
        if (namaObat.isEmpty) continue;
        final analisis = await LayananPenjualan.analyzeObat(namaObat);
        items.add(_DrugChecklistItem(
          analisis: analisis,
          isChecked: analisis.dapatkanRekomendasi().startsWith('Beli'),
          jumlahBeli: _calculateRestockAmount(analisis),
        ));
      }

      items.sort((a, b) {
        final aPriority = _getPriority(a.analisis.dapatkanRekomendasi());
        final bPriority = _getPriority(b.analisis.dapatkanRekomendasi());
        return aPriority.compareTo(bPriority);
      });

      setState(() {
        _checklistItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  int _getPriority(String rekomendasi) {
    if (rekomendasi.startsWith('Beli')) return 0;
    if (rekomendasi.startsWith('Jual')) return 1;
    return 2;
  }

  int _calculateRestockAmount(AnalisisTren analisis) {
    if (analisis.tren > 0.2) return 50;
    if (analisis.tren > 0) return 30;
    return 20;
  }

  int get _checkedCount => _checklistItems.where((item) => item.isChecked).length;
  int get _pengadaanCount => _checklistItems.where((item) => item.analisis.dapatkanRekomendasi().startsWith('Beli')).length;
  int get _totalQuantity {
    int total = 0;
    for (var item in _checklistItems) {
      if (item.isChecked) {
        total += item.jumlahBeli;
      }
    }
    return total;
  }

  void _toggleItem(int index) {
    setState(() {
      _checklistItems[index].isChecked = !_checklistItems[index].isChecked;
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final newQty = _checklistItems[index].jumlahBeli + delta;
      if (newQty >= 5) {
        _checklistItems[index].jumlahBeli = newQty;
      }
    });
  }

  Future<void> _showQuantityDialog(BuildContext context, int index, int currentValue) async {
    final controller = TextEditingController(text: currentValue.toString());

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masukkan Jumlah'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah Unit',
            hintText: 'Contoh: 50',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= 5) {
                Navigator.pop(context, value);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _checklistItems[index].jumlahBeli = result;
      });
    }
  }

  void _toggleSelectAll(bool value) {
    setState(() {
      for (var item in _checklistItems) {
        if (item.analisis.dapatkanRekomendasi().startsWith('Beli')) {
          item.isChecked = value;
        }
      }
    });
  }

  Future<void> _simpanRekomendasi() async {
    if (_checkedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 obat untuk disimpan'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final checkedItems = _checklistItems.where((i) => i.isChecked).toList();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.checklist, color: Colors.deepPurple, size: 20),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Konfirmasi Rencana',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_cart, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_checkedCount obat ($_totalQuantity unit)',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Daftar Pengadaan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: checkedItems.length,
                  itemBuilder: (context, idx) {
                    final item = checkedItems[idx];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${idx + 1}.',
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.analisis.namaObat,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${item.jumlahBeli}',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Simpan'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Menyimpan...'),
          ],
        ),
      ),
    );

    try {
      final restockList = _checklistItems
          .where((item) => item.isChecked)
          .map((item) => ItemStokUlang(
                nama: item.analisis.namaObat,
                saran: 'Pengadaan',
                jumlah: item.jumlahBeli,
                alasan: item.analisis.dapatkanRekomendasi(),
              ))
          .toList();

      final tidakRestockList = _checklistItems
          .where((item) => !item.isChecked)
          .map((item) => ItemTidakRestok(
                nama: item.analisis.namaObat,
                alasan: item.analisis.dapatkanRekomendasi(),
              ))
          .toList();

      await LayananFirestore.simpanRekomendasi(
        restock: restockList,
        tidakRestock: tidakRestockList,
      );

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Rencana kulakan tersimpan ($_checkedCount obat, $_totalQuantity unit)'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() {
          for (var item in _checklistItems) {
            item.isChecked = item.analisis.dapatkanRekomendasi().startsWith('Beli');
            item.jumlahBeli = _calculateRestockAmount(item.analisis);
          }
        });
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildBadgeWidget(String rekomendasi) {
    Color bgColor;
    IconData icon;
    String label;

    if (rekomendasi.startsWith('Beli')) {
      bgColor = Colors.green;
      icon = Icons.shopping_cart;
      label = 'Pengadaan';
    } else if (rekomendasi.startsWith('Jual')) {
      bgColor = Colors.orange;
      icon = Icons.local_offer;
      label = 'Prioritas';
    } else {
      bgColor = Colors.blue;
      icon = Icons.check_circle;
      label = 'Optimum';
    }

    return SizedBox(
      width: 70,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tampilkanDaftarEkspansi() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 100),
      itemCount: _checklistItems.length,
      itemBuilder: (context, index) {
        final item = _checklistItems[index];
        final analisis = item.analisis;
        final rekomendasi = analisis.dapatkanRekomendasi();
        final isBeli = rekomendasi.startsWith('Beli');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: ExpansionTile(
            leading: _buildBadgeWidget(rekomendasi),
            title: Text(
              analisis.namaObat,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    analisis.tren > 0.2
                        ? Icons.trending_up
                        : analisis.tren < -0.2
                            ? Icons.trending_down
                            : Icons.trending_flat,
                    size: 14,
                    color: analisis.tren > 0.2
                        ? Colors.green
                        : analisis.tren < -0.2
                            ? Colors.red
                            : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${analisis.dapatkanLabelTren()} • Stok: ${analisis.stokTerkini}',
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBeli) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: item.isChecked,
                                  onChanged: (_) => _toggleItem(index),
                                  activeColor: Colors.green,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Flexible(
                                  child: Text(
                                    'Tambahkan ke rencana pengadaan',
                                    style: TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Jumlah Unit:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                const Spacer(),
                                InkWell(
                                  onTap: item.jumlahBeli > 5 ? () => _updateQuantity(index, -5) : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: item.jumlahBeli > 5 ? Colors.deepPurple.shade100 : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(Icons.remove, size: 18, color: item.jumlahBeli > 5 ? Colors.deepPurple : Colors.grey),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => _showQuantityDialog(context, index, item.jumlahBeli),
                                  child: Container(
                                    width: 60,
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.deepPurple),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${item.jumlahBeli}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _updateQuantity(index, 5),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(Icons.add, size: 18, color: Colors.deepPurple),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text('unit', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildInfoRow('Penjualan Bulan Ini:', '${analisis.totalPenjualanBulanIni} unit'),
                    const SizedBox(height: 6),
                    _buildInfoRow('Penjualan Bulan Lalu:', '${analisis.totalPenjualanBulanLalu} unit'),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      'Stok Terkini:',
                      '${analisis.stokTerkini} unit',
                      color: analisis.stokTerkini < 10 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      'Tren Perubahan:',
                      '${(analisis.tren * 100).toStringAsFixed(0)}%',
                      color: analisis.tren > 0 ? Colors.green : Colors.red,
                    ),
                    const Divider(height: 16),
                    const Text(
                      'REKOMENDASI:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Text(
                        rekomendasi,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Cerdas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (_checklistItems.isNotEmpty && _pengadaanCount > 0)
            TextButton.icon(
              onPressed: () {
                final allSelected = _checkedCount == _pengadaanCount;
                _toggleSelectAll(!allSelected);
              },
              icon: Icon(
                _checkedCount == _pengadaanCount ? Icons.check_box : Icons.check_box_outline_blank,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                _checkedCount == _pengadaanCount ? 'Uncheck' : 'Check All',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.deepPurple.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.auto_graph, color: Colors.deepPurple, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Smart Rekomendasi berdasarkan Tren Penjualan, Stok, dan FEFO',
                    style: TextStyle(fontSize: 12, color: Colors.deepPurple),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : buatRekomendasi,
              icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_graph),
              label: Text(_isLoading ? 'Menganalisis...' : 'Jalankan Analisis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700], fontSize: 12))),
                  ],
                ),
              ),
            ),
          if (_checklistItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryChip('Total', '${_checklistItems.length}', Colors.deepPurple, Icons.inventory),
                  _buildSummaryChip('Pengadaan', '$_pengadaanCount', Colors.green, Icons.shopping_cart),
                  _buildSummaryChip('Dipilih', '$_checkedCount', Colors.blue, Icons.check),
                ],
              ),
            ),
          Expanded(
            child: _checklistItems.isEmpty && !_isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.psychology, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Tekan tombol di atas untuk\nmemulai analisis',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : tampilkanDaftarEkspansi(),
          ),
        ],
      ),
      bottomSheet: _checklistItems.isNotEmpty && _pengadaanCount > 0
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_checkedCount dipilih',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
                          ),
                          if (_checkedCount > 0)
                            Text('$_totalQuantity unit total', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _checkedCount > 0 ? _simpanRekomendasi : null,
                      icon: const Icon(Icons.save),
                      label: Text(_checkedCount > 0 ? 'Simpan ($_checkedCount)' : 'Pilih Obat', style: const TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _checkedCount > 0 ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text('$value $label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
        ),
      ],
    );
  }
}

class _DrugChecklistItem {
  final AnalisisTren analisis;
  bool isChecked;
  int jumlahBeli;

  _DrugChecklistItem({
    required this.analisis,
    required this.isChecked,
    required this.jumlahBeli,
  });
}
