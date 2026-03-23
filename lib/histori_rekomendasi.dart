import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/firestore_service.dart';

class HistoriRekomendasiPage extends StatelessWidget {
  const HistoriRekomendasiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Histori Rekomendasi"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.streamHistori(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Belum ada histori rekomendasi."),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final restock = data['restock'] as List;
              final tidakRestock = data['tidak_restock'] as List;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ExpansionTile(
                  title: Text(
                    "Rekomendasi - ${data['sumber']}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    data['createdAt'] != null
                        ? data['createdAt'].toDate().toString()
                        : '-',
                  ),
                  children: [
                    const Text("🟢 Perlu Dibeli Ulang"),
                    ...restock.map((e) => ListTile(
                      title: Text(e['nama']),
                      subtitle: Text(e['alasan']),
                      trailing: Text("+${e['jumlah']}"),
                    )),
                    const Divider(),
                    const Text("🔴 Tidak Perlu Dibeli"),
                    ...tidakRestock.map((e) => ListTile(
                      title: Text(e['nama']),
                      subtitle: Text(e['alasan']),
                    )),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
