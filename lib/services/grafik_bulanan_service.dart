import 'package:cloud_firestore/cloud_firestore.dart';

class GrafikBulananService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<List<int>> streamRestockPerBulan() {
    final int tahunSekarang = DateTime.now().year;

    return _db.collection('penjualan').snapshots().asyncMap((snapshot) async {
      final List<int> bulanan = List.filled(12, 0);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? ts = data['createdAt'];
        if (ts == null) continue;

        final DateTime tanggal = ts.toDate();
        if (tanggal.year != tahunSekarang) continue;

        final int bulanIndex = tanggal.month - 1;
        final List items = data['items'] ?? [];

        for (var item in items) {
          final num jumlah = item['jumlah'] ?? 0;
          bulanan[bulanIndex] += jumlah.toInt();
        }
      }

      return bulanan;
    });
  }

  static Stream<List<double>> streamTotalRupiahPerBulan() {
    final int tahunSekarang = DateTime.now().year;

    return _db.collection('penjualan').snapshots().asyncMap((snapshot) async {
      final List<double> bulanan = List.filled(12, 0.0);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? ts = data['createdAt'];
        if (ts == null) continue;

        final DateTime tanggal = ts.toDate();
        if (tanggal.year != tahunSekarang) continue;

        final int bulanIndex = tanggal.month - 1;
        final num total = data['total'] ?? 0;

        bulanan[bulanIndex] += total.toDouble();
      }

      return bulanan;
    });
  }

  static Stream<List<double>> streamKeuntunganPerBulan() {
    final int tahunSekarang = DateTime.now().year;

    return _db.collection('penjualan').snapshots().asyncMap((snapshot) async {
      final List<double> bulanan = List.filled(12, 0.0);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? ts = data['createdAt'];
        if (ts == null) continue;

        final DateTime tanggal = ts.toDate();
        if (tanggal.year != tahunSekarang) continue;

        final int bulanIndex = tanggal.month - 1;
        final List items = data['items'] ?? [];

        double keuntunganBulan = 0.0;
        for (var item in items) {
          final num jumlah = item['jumlah'] ?? 0;
          final num harga = item['harga'] ?? 0;
          final num hargaBeli = item['hargaBeli'] ?? 0;
          keuntunganBulan += (harga.toDouble() - hargaBeli.toDouble()) * jumlah.toDouble();
        }
        bulanan[bulanIndex] += keuntunganBulan;
      }

      return bulanan;
    });
  }
}
