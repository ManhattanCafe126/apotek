import 'package:cloud_firestore/cloud_firestore.dart';

class GrafikCompareService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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
          final num jumlah = item['jumlah'] ?? 0;
          total += jumlah.toInt();
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
