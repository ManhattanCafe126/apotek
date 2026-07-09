import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/grafik_bulanan_service.dart';

String formatRupiah(double amount) {
  return 'Rp. ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

class TampilanGrafikPerbandingan extends StatefulWidget {
  const TampilanGrafikPerbandingan({super.key});

  static const List<String> namaBulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  State<TampilanGrafikPerbandingan> createState() => _TampilanGrafikPerbandinganState();
}

class _TampilanGrafikPerbandinganState extends State<TampilanGrafikPerbandingan> {
  int tahunTerpilih = DateTime.now().year;

  void pilihTahun(int tahun) {
    setState(() {
      tahunTerpilih = tahun;
    });
  }

  Color _getBarColor(int value, int maxValue) {
    if (value == 0) return Colors.grey;
    final ratio = value / maxValue;
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.6) return Colors.lightGreen;
    if (ratio >= 0.4) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final List<int> daftarTahun = List.generate(
      5,
      (index) => DateTime.now().year - index,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Grafik Penjualan $tahunTerpilih"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<int>(
              value: tahunTerpilih,
              dropdownColor: Colors.deepPurple,
              style: const TextStyle(color: Colors.white),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: daftarTahun.map((tahun) {
                return DropdownMenuItem<int>(
                  value: tahun,
                  child: Text(
                    tahun.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (tahun) {
                if (tahun != null) {
                  pilihTahun(tahun);
                }
              },
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<int>>(
        stream: GrafikBulananService.streamRestockPerBulan(),
        builder: (context, unitSnapshot) {
          if (!unitSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<double>>(
            stream: GrafikBulananService.streamTotalRupiahPerBulan(),
            builder: (context, rupiahSnapshot) {
              if (!rupiahSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<List<double>>(
                stream: GrafikBulananService.streamKeuntunganPerBulan(),
                builder: (context, profitSnapshot) {
                  if (!profitSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final unitData = unitSnapshot.data!;
                  final rupiahData = rupiahSnapshot.data!;
                  final profitData = profitSnapshot.data!;
                  final double maxValue = unitData.isEmpty
                      ? 100.0
                      : (unitData.reduce((a, b) => a > b ? a : b)).toDouble();
                  final double maxProfit = profitData.isEmpty
                      ? 100.0
                      : (profitData.reduce((a, b) => a > b ? a : b));
                  final totalUnit = unitData.fold<int>(0, (sum, val) => sum + val);
                  final totalRupiah = rupiahData.fold<double>(
                    0,
                    (sum, val) => sum + val,
                  );
                  final totalProfit = profitData.fold<double>(
                    0,
                    (sum, val) => sum + val,
                  );

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade400,
                                  Colors.deepPurple.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Penjualan Tahun $tahunTerpilih',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$totalUnit unit',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatRupiah(totalRupiah),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rata-rata/bulan: ${(totalUnit / 12).toStringAsFixed(0)} unit',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Puncak: ${maxValue.toInt()} unit',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          tampilkanGrafikBatang(unitData, maxValue),
                          const SizedBox(height: 16),
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Detail Penjualan',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: DataTable(
                                      columns: const [
                                        DataColumn(label: Text('Bulan')),
                                        DataColumn(
                                          label: Text('Unit'),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: Text('Total Rupiah'),
                                          numeric: true,
                                        ),
                                        DataColumn(
                                          label: Text('Keuntungan'),
                                          numeric: true,
                                        ),
                                      ],
                                      rows: List.generate(
                                        12,
                                        (index) => DataRow(
                                          cells: [
                                            DataCell(
                                              Text(
                                                TampilanGrafikPerbandingan.namaBulan[index],
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                '${unitData[index]} unit',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                formatRupiah(rupiahData[index]),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                formatRupiah(profitData[index]),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: profitData[index] >= 0
                                                      ? Colors.teal
                                                      : Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade400,
                                  Colors.teal.shade700,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Keuntungan Tahun $tahunTerpilih',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  formatRupiah(totalProfit),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Margin: ${totalRupiah > 0 ? ((totalProfit / totalRupiah) * 100).toStringAsFixed(1) : 0}%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Rata-rata/bulan: ${formatRupiah(totalProfit / 12)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                    Text(
                                      'Puncak: ${formatRupiah(maxProfit)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          tampilkanGrafikBatangKeuntungan(profitData, maxProfit),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// Render Bar Chart for Sales
  Widget tampilkanGrafikBatang(List<int> unitData, double maxValue) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penjualan Per Bulan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue + 10,
                  barGroups: List.generate(12, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: unitData[i].toDouble(),
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                          color: _getBarColor(
                            unitData[i],
                            maxValue.toInt(),
                          ),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              TampilanGrafikPerbandingan.namaBulan[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: maxValue / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Render Bar Chart for Profit
  Widget tampilkanGrafikBatangKeuntungan(List<double> profitData, double maxProfit) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Keuntungan Per Bulan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxProfit + (maxProfit * 0.2),
                  minY: profitData.any((p) => p < 0) ? (profitData.reduce((a, b) => a < b ? a : b) * 1.2) : 0.0,
                  barGroups: List.generate(12, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: profitData[i],
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                          color: profitData[i] >= 0 ? Colors.teal : Colors.red,
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              TampilanGrafikPerbandingan.namaBulan[value.toInt()],
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                        reservedSize: 50,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    horizontalInterval: (maxProfit / 5).toDouble(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
