import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/grafik_bulanan_service.dart';

/// Format currency to Rupiah with thousand separator
String formatRupiah(double amount) {
  return 'Rp. ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
}

class GrafikBulananPage extends StatefulWidget {
  const GrafikBulananPage({super.key});

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
  State<GrafikBulananPage> createState() => _GrafikBulananPageState();
}

class _GrafikBulananPageState extends State<GrafikBulananPage> {
  @override
  Widget build(BuildContext context) {
    final int tahun = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text("Grafik Penjualan $tahun"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
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

              final unitData = unitSnapshot.data!;
              final rupiahData = rupiahSnapshot.data!;
              final maxValue = unitData.isEmpty
                  ? 100
                  : (unitData.reduce((a, b) => a > b ? a : b)).toDouble();
              final totalUnit = unitData.fold<int>(0, (sum, val) => sum + val);
              final totalRupiah = rupiahData.fold<double>(
                0,
                (sum, val) => sum + val,
              );

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // STATISTIK RINGKAS
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
                            const Text(
                              'Total Penjualan Tahun Ini',
                              style: TextStyle(
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

                      // GRAFIK BAR CHART
                      Card(
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
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
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
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                GrafikBulananPage
                                                    .namaBulan[value.toInt()],
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
                                              style: const TextStyle(
                                                fontSize: 9,
                                              ),
                                            );
                                          },
                                          reservedSize: 40,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      drawHorizontalLine: true,
                                      horizontalInterval: maxValue / 5,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey.withValues(
                                            alpha: 0.2,
                                          ),
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
                      ),
                      const SizedBox(height: 16),

                      // TABEL DATA
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
                                  ],
                                  rows: List.generate(
                                    12,
                                    (index) => DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            GrafikBulananPage.namaBulan[index],
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
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getBarColor(int value, int maxValue) {
    if (value == 0) return Colors.grey;
    final ratio = value / maxValue;
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.6) return Colors.lightGreen;
    if (ratio >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
