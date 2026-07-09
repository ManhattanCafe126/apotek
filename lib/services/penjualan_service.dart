import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/penjualan_model.dart';

class LayananPenjualan {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static Future<List<Penjualan>> getPenjualanByMonth(
    int month,
    int year,
  ) async {
    try {
      final DateTime awalBulan = DateTime(year, month, 1);
      final DateTime akhirBulan = DateTime(year, month + 1, 0);

      final snapshot = await _db
          .collection('penjualan')
          .where('createdAt', isGreaterThanOrEqualTo: awalBulan)
          .where('createdAt', isLessThanOrEqualTo: akhirBulan)
          .get();

      return snapshot.docs
          .map((doc) => Penjualan.dariMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getPenjualanByMonth: $e');
      return [];
    }
  }

  static Future<Map<String, int>> getTotalPenjualanPerObatByMonth(
    int month,
    int year,
  ) async {
    try {
      final penjualanList = await getPenjualanByMonth(month, year);
      final Map<String, int> result = {};

      for (var penjualan in penjualanList) {
        for (var item in penjualan.items) {
          result[item.nama] = (result[item.nama] ?? 0) + item.jumlah;
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error getTotalPenjualanPerObatByMonth: $e');
      return {};
    }
  }

  static Future<double> calculateTren(String namaObat) async {
    try {
      final now = DateTime.now();
      final bulanIni = await getTotalPenjualanPerObatByMonth(
        now.month,
        now.year,
      );
      final bulanLalu = now.month == 1
          ? await getTotalPenjualanPerObatByMonth(12, now.year - 1)
          : await getTotalPenjualanPerObatByMonth(now.month - 1, now.year);

      final jumlahIni = bulanIni[namaObat] ?? 0;
      final jumlahLalu = bulanLalu[namaObat] ?? 0;

      if (jumlahLalu == 0) return 0.0;

      final perubahan = (jumlahIni - jumlahLalu) / jumlahLalu;
      return perubahan.clamp(-1.0, 1.0);
    } catch (e) {
      debugPrint('Error calculateTren: $e');
      return 0.0;
    }
  }

  static Future<int> getStokTerkini(String namaObat) async {
    try {
      final snapshot = await _db
          .collection('obat')
          .where('nama', isEqualTo: namaObat)
          .get();

      int totalStok = 0;
      for (var doc in snapshot.docs) {
        final jumlah = doc.data()['jumlah_stok'] ?? 0;
        totalStok += (jumlah as num).toInt();
      }

      return totalStok;
    } catch (e) {
      debugPrint('Error getStokTerkini: $e');
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getDetailStokFEFO(
    String namaObat,
  ) async {
    try {
      final snapshot = await _db
          .collection('obat')
          .where('nama', isEqualTo: namaObat)
          .get();

      final stokList = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'batch': data['batch'] ?? '',
          'exp_date': data['exp_date'] ?? '',
          'jumlah_stok': data['jumlah_stok'] ?? 0,
        };
      }).toList();

      stokList.sort((a, b) {
        final dateA = _parseDate(a['exp_date'] as String);
        final dateB = _parseDate(b['exp_date'] as String);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

      return stokList;
    } catch (e) {
      debugPrint('Error getDetailStokFEFO: $e');
      return [];
    }
  }

  static DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  static Future<AnalisisTren> analyzeObat(String namaObat) async {
    try {
      final now = DateTime.now();

      final penjualanBulanIni =
          (await getTotalPenjualanPerObatByMonth(
            now.month,
            now.year,
          ))[namaObat] ??
          0;

      final penjualanBulanLalu = now.month == 1
          ? (await getTotalPenjualanPerObatByMonth(
                  12,
                  now.year - 1,
                ))[namaObat] ??
                0
          : (await getTotalPenjualanPerObatByMonth(
                  now.month - 1,
                  now.year,
                ))[namaObat] ??
                0;

      final tren = await calculateTren(namaObat);
      final stokTerkini = await getStokTerkini(namaObat);
      final detailStok = await getDetailStokFEFO(namaObat);

      return AnalisisTren(
        namaObat: namaObat,
        tren: tren,
        totalPenjualanBulanIni: penjualanBulanIni,
        totalPenjualanBulanLalu: penjualanBulanLalu,
        stokTerkini: stokTerkini,
        stokDetail: detailStok,
      );
    } catch (e) {
      debugPrint('Error analyzeObat: $e');
      return AnalisisTren(
        namaObat: namaObat,
        tren: 0.0,
        totalPenjualanBulanIni: 0,
        totalPenjualanBulanLalu: 0,
        stokTerkini: 0,
        stokDetail: [],
      );
    }
  }

  static Future<List<String>> getAllObatNames() async {
    try {
      final penjualanSnapshot = await _db.collection('penjualan').get();
      final Set<String> obatNames = {};

      for (var doc in penjualanSnapshot.docs) {
        final data = doc.data();
        final items = data['items'] as List? ?? [];
        for (var item in items) {
          obatNames.add(item['nama'] ?? '');
        }
      }

      return obatNames.toList()..sort();
    } catch (e) {
      debugPrint('Error getAllObatNames: $e');
      return [];
    }
  }

  static Stream<List<int>> streamPenjualanPerBulan() {
    final int tahun = DateTime.now().year;

    return _db.collection('penjualan').snapshots().asyncMap((snapshot) async {
      final List<int> bulanan = List.filled(12, 0);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? ts = data['createdAt'];
        if (ts == null) continue;

        final DateTime tanggal = ts.toDate();

        if (tanggal.year != tahun) continue;

        final int bulanIndex = tanggal.month - 1;
        final List items = data['items'] ?? [];

        for (var item in items) {
          final jumlah = item['jumlah'] ?? 0;
          bulanan[bulanIndex] += (jumlah as num).toInt();
        }
      }

      return bulanan;
    });
  }

  static Stream<Map<int, List<int>>> streamPerbandinganTahun(
    int tahunAktif,
    int tahunLalu,
  ) {
    return _db.collection('penjualan').snapshots().asyncMap((snapshot) async {
      final List<int> dataAktif = List.filled(12, 0);
      final List<int> dataLalu = List.filled(12, 0);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? ts = data['createdAt'];
        if (ts == null) continue;

        final date = ts.toDate();
        final int bulanIndex = date.month - 1;
        final List items = data['items'] ?? [];

        int total = 0;
        for (var item in items) {
          final jumlah = item['jumlah'] ?? 0;
          total += (jumlah as num).toInt();
        }

        if (date.year == tahunAktif) {
          dataAktif[bulanIndex] += total;
        } else if (date.year == tahunLalu) {
          dataLalu[bulanIndex] += total;
        }
      }

      return {tahunAktif: dataAktif, tahunLalu: dataLalu};
    });
  }
}
