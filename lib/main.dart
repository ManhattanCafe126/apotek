import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ocr/firebase_options.dart';
import 'riset_mlkit.dart';
import 'rekomendasi.dart';
import 'histori_rekomendasi.dart';
import 'grafik_bulanan_page.dart';
import 'tambah_obat_page.dart';
import 'manajemen_obat_page.dart';
import 'penjualan_page.dart';
import 'histori_penjualan_page.dart';
import 'laporan_kadarluarsa_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('Anonymous login berhasil');
  } catch (e) {
    debugPrint('Anonymous login gagal: $e');
  }

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
      home: const TampilanDashboard(),
    );
  }
}

/// Reusable Menu Card Widget
class MenuCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const MenuCard({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: Card(
            elevation: _isHovered ? 8 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: widget.backgroundColor,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.backgroundColor,
                    widget.backgroundColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.icon, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
}

/// Menu Item Data Model
class MenuItemData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  MenuItemData({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

/// Main Dashboard Page
class TampilanDashboard extends StatefulWidget {
  const TampilanDashboard({super.key});

  @override
  State<TampilanDashboard> createState() => _TampilanDashboardState();
}

class _TampilanDashboardState extends State<TampilanDashboard> {
  int _selectedIndex = 0;

  static const Color stockColor = Color(0xFF42A5F5);
  static const Color salesColor = Color(0xFF66BB6A);
  static const Color analyticsColor = Color(0xFF7E57C2);

  void navigasiKeFitur(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  /// Build custom bottom nav item
  Widget _buildNavItem(int index, IconData icon, String label, Color color) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apotek Anisah Farma'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          bangunTampilan(),
          bangunTampilan(),
          bangunTampilan(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.inventory_2, 'Stok', stockColor),
                _buildNavItem(1, Icons.attach_money, 'Penjualan', salesColor),
                _buildNavItem(2, Icons.analytics, 'Analisis', analyticsColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build Stok page
  Widget bangunTampilan() {
    if (_selectedIndex == 0) {
      final stockItems = [
        MenuItemData(
          title: 'Scan\nFaktur',
          icon: Icons.camera_alt,
          color: stockColor,
          onTap: () => navigasiKeFitur(const PengontrolOCR()),
        ),
        MenuItemData(
          title: 'Manajemen\nObat',
          icon: Icons.medical_services,
          color: stockColor,
          onTap: () => navigasiKeFitur(const TampilanManajemenObat()),
        ),
        MenuItemData(
          title: 'Tambah Obat',
          icon: Icons.add_box,
          color: stockColor,
          onTap: () => navigasiKeFitur(const TampilanTambahObat()),
        ),
      ];

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Manajemen Stok', Icons.inventory_2, stockColor),
            _buildCategoryGrid(stockItems),
          ],
        ),
      );
    } else if (_selectedIndex == 1) {
      final salesItems = [
        MenuItemData(
          title: 'Penjualan',
          icon: Icons.shopping_cart,
          color: salesColor,
          onTap: () => navigasiKeFitur(const TampilanPenjualan()),
        ),
        MenuItemData(
          title: 'Histori\nPenjualan',
          icon: Icons.history,
          color: salesColor,
          onTap: () => navigasiKeFitur(const TampilanRiwayatPenjualan()),
        ),
      ];

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Penjualan', Icons.attach_money, salesColor),
            _buildCategoryGrid(salesItems),
          ],
        ),
      );
    } else {
      final analyticsItems = [
        MenuItemData(
          title: 'Laporan\nKadaluwarsa',
          icon: Icons.schedule,
          color: analyticsColor,
          onTap: () => navigasiKeFitur(const TampilanLaporanKedaluwarsa()),
        ),
        MenuItemData(
          title: 'Rekomendasi\nCerdas (AI)',
          icon: Icons.psychology,
          color: analyticsColor,
          onTap: () => navigasiKeFitur(const TampilanRekomendasiPenjualan()),
        ),
        MenuItemData(
          title: 'Histori\nRekomendasi',
          icon: Icons.history,
          color: analyticsColor,
          onTap: () => navigasiKeFitur(const TampilanRiwayatRekomendasi()),
        ),
        MenuItemData(
          title: 'Grafik\nPenjualan',
          icon: Icons.bar_chart,
          color: analyticsColor,
          onTap: () => navigasiKeFitur(const TampilanGrafikPerbandingan()),
        ),
      ];

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader('Analisis & Rekomendasi', Icons.analytics, analyticsColor),
            _buildCategoryGrid(analyticsItems),
          ],
        ),
      );
    }
  }

  /// Build page header
  Widget _buildPageHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: color.withValues(alpha: 0.3), thickness: 2),
        ],
      ),
    );
  }

  /// Build category grid
  Widget _buildCategoryGrid(List<MenuItemData> items) {
    final crossAxisCount = items.length > 4 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuCard(
          title: item.title,
          icon: item.icon,
          backgroundColor: item.color,
          onTap: item.onTap,
        );
      },
    );
  }
}
