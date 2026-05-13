import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ocr/firebase_options.dart';
import 'riset_mlkit.dart';
import 'rekomendasi.dart';
import 'histori_rekomendasi.dart';
import 'grafik_bulanan_page.dart';
import 'stock_opname_page.dart';
import 'tambah_obat_page.dart';
import 'manajemen_obat_page.dart';
import 'penjualan_page.dart';
import 'histori_penjualan_page.dart';
import 'laporan_kadarluarsa_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Login anonymous untuk akses Firestore
  try {
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('✅ Anonymous login berhasil');
  } catch (e) {
    debugPrint('❌ Anonymous login gagal: $e');
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
      home: const HalamanMenuUtama(),
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

/// Menu Category Section Widget
class MenuCategorySection extends StatelessWidget {
  final String categoryTitle;
  final IconData categoryIcon;
  final Color categoryColor;
  final List<MenuItemData> items;

  const MenuCategorySection({
    super.key,
    required this.categoryTitle,
    required this.categoryIcon,
    required this.categoryColor,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Icon(categoryIcon, size: 24, color: categoryColor),
              const SizedBox(width: 12),
              Text(
                categoryTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            color: categoryColor.withValues(alpha: 0.3),
            thickness: 2,
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
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
        ),
      ],
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

/// Main Menu Page
class HalamanMenuUtama extends StatefulWidget {
  const HalamanMenuUtama({super.key});

  @override
  State<HalamanMenuUtama> createState() => _HalamanMenuUtamaState();
}

class _HalamanMenuUtamaState extends State<HalamanMenuUtama> {
  int _selectedIndex = 0;

  // Define colors for categories
  static const Color stockColor = Color(0xFF42A5F5); // Blue
  static const Color salesColor = Color(0xFF66BB6A); // Green
  static const Color analyticsColor = Color(0xFF7E57C2); // Purple

  /// Build Manajemen Stok page
  Widget _buildStokPage() {
    final stockItems = [
      MenuItemData(
        title: 'Scan\nFaktur',
        icon: Icons.camera_alt,
        color: stockColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RisetMLKitPage()),
        ),
      ),
      MenuItemData(
        title: 'Manajemen\nObat',
        icon: Icons.medical_services,
        color: stockColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManajemenObatPage()),
        ),
      ),
      MenuItemData(
        title: 'Tambah Obat\nManual',
        icon: Icons.add_box,
        color: stockColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TambahObatPage()),
        ),
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
  }

  /// Build Penjualan page
  Widget _buildPenjualanPage() {
    final salesItems = [
      MenuItemData(
        title: 'Penjualan',
        icon: Icons.shopping_cart,
        color: salesColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PenjualanPage()),
        ),
      ),
      MenuItemData(
        title: 'Histori\nPenjualan',
        icon: Icons.history,
        color: salesColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoriPenjualanPage()),
        ),
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
  }

  /// Build Analisis & Rekomendasi page
  Widget _buildAnalisisPage() {
    final analyticsItems = [
      MenuItemData(
        title: 'Laporan\nKadarluarsa',
        icon: Icons.schedule,
        color: analyticsColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LaporanKadarluarsaPage(),
          ),
        ),
      ),
      MenuItemData(
        title: 'Rekomendasi\nCerdas (AI)',
        icon: Icons.psychology,
        color: analyticsColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RekomendasiPage()),
        ),
      ),
      MenuItemData(
        title: 'Histori\nRekomendasi',
        icon: Icons.history,
        color: analyticsColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HistoriRekomendasiPage(),
          ),
        ),
      ),
      MenuItemData(
        title: 'Grafik\nper Bulan',
        icon: Icons.bar_chart,
        color: analyticsColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GrafikBulananPage()),
        ),
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(
            'Analisis & Rekomendasi',
            Icons.analytics,
            analyticsColor,
          ),
          _buildCategoryGrid(analyticsItems),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          _buildStokPage(),
          _buildPenjualanPage(),
          _buildAnalisisPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stok'),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Penjualan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analisis',
          ),
        ],
      ),
    );
  }
}
