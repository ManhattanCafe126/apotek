import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rekomendasi_model.dart';

class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// SIMPAN REKOMENDASI
  static Future<void> simpanRekomendasi({
    required List<RestockItem> restock,
    required List<TidakRestockItem> tidakRestock,
  }) async {
    await _db.collection('rekomendasi').add({
      'createdAt': FieldValue.serverTimestamp(),
      'sumber': 'AI',
      'restock': restock.map((e) => e.toMap()).toList(),
      'tidak_restock': tidakRestock.map((e) => e.toMap()).toList(),
    });
  }

  /// AMBIL HISTORI REKOMENDASI
  static Stream<QuerySnapshot> streamHistori() {
    return _db
        .collection('rekomendasi')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
