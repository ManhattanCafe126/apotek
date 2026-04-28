import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/grafik_compare_service.dart';

class GrafikComparePage extends StatefulWidget {
  const GrafikComparePage({super.key});

  @override
  State<GrafikComparePage> createState() => _GrafikComparePageState();
}

class _GrafikComparePageState extends State<GrafikComparePage> {
  late int _tahunDipilih;

  static const List<String> bulan = [
    'Jan','Feb','Mar','Apr','Mei','Jun',
    'Jul','Agu','Sep','Okt','Nov','Des'
  ];

  @override
  void initState() {
    super.initState();
    _tahunDipilih = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final int tahunLalu = _tahunDipilih - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perbandingan Restock Tahunan"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ================= DROPDOWN =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<int>(
              value: _tahunDipilih,
              isExpanded: true,
              items: List.generate(5, (i) {
                final tahun = DateTime.now().year - i;
                return DropdownMenuItem(
                  value: tahun,
                  child: Text("Tahun $tahun"),
                );
              }),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tahunDipilih = value);
                }
              },
            ),
          ),

          // ================= GRAFIK =================
          Expanded(
            child: StreamBuilder<Map<int, List<int>>>(
              stream: GrafikCompareService.streamPerbandinganTahun(
                _tahunDipilih,
                tahunLalu,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final dataAktif = snapshot.data![_tahunDipilih]!;
                final dataLalu = snapshot.data![tahunLalu]!;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: List.generate(12, (i) {
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: dataAktif[i].toDouble(),
                              width: 8,
                            ),
                            BarChartRodData(
                              toY: dataLalu[i].toDouble(),
                              width: 8,
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(bulan[value.toInt()]);
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: true),
                    ),
                  ),
                );
              },
            ),
          ),

          // ================= LEGEND =================
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legend(Colors.blue, "Tahun $_tahunDipilih"),
                const SizedBox(width: 16),
                _legend(Colors.orange, "Tahun $tahunLalu"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
