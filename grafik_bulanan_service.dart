import 'package:cloud_firestore/cloud_firestore.dart';

class GrafikBulananService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Ambil total restock per bulan (1 tahun aktif)
  static Stream<List<int>> streamRestockPerBulan() {
    final int tahunSekarang = DateTime.now().year;

    return _db.collection('rekomendasi').snapshots().map((snapshot) {
      // Index 0 = Jan, 11 = Des
      final List<int> bulanan = List.filled(12, 0);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final Timestamp? ts = data['createdAt'];
        if (ts == null) continue;

        final DateTime tanggal = ts.toDate();

        // 🔒 FILTER TAHUN AKTIF
        if (tanggal.year != tahunSekarang) continue;

        final int bulanIndex = tanggal.month - 1;
        final List restock = data['restock'] ?? [];

        for (var item in restock) {
          final num jumlah = item['jumlah'] ?? 0;
          bulanan[bulanIndex] += jumlah.toInt();
        }
      }

      return bulanan;
    });
  }
}
