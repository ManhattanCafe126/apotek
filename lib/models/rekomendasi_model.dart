class ItemStokUlang {
  final String nama;
  final String saran;
  final int jumlah;
  final String alasan;

  ItemStokUlang({
    required this.nama,
    required this.saran,
    required this.jumlah,
    required this.alasan,
  });

  factory ItemStokUlang.fromJson(Map<String, dynamic> json) {
    return ItemStokUlang(
      nama: json['nama']?.toString() ?? '',
      saran: json['saran']?.toString() ?? '',
      jumlah: int.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      alasan: json['alasan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'saran': saran,
    'jumlah': jumlah,
    'alasan': alasan,
  };
}

class ItemTidakRestok {
  final String nama;
  final String alasan;

  ItemTidakRestok({
    required this.nama,
    required this.alasan,
  });

  factory ItemTidakRestok.fromJson(Map<String, dynamic> json) {
    return ItemTidakRestok(
      nama: json['nama']?.toString() ?? '',
      alasan: json['alasan']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'alasan': alasan,
  };
}

class ModelRekomendasi {
  final List<ItemStokUlang> daftarStokUlang;
  final List<ItemTidakRestok> daftarTidakStokUlang;
  final DateTime? tanggalDibuat;

  ModelRekomendasi({
    required this.daftarStokUlang,
    required this.daftarTidakStokUlang,
    this.tanggalDibuat,
  });

  factory ModelRekomendasi.fromJson(Map<String, dynamic> json) {
    final restockList = (json['restock'] as List<dynamic>?)
        ?.map((e) => ItemStokUlang.fromJson(Map<String, dynamic>.from(e)))
        .toList() ?? [];

    final tidakRestockList = (json['tidakRestock'] as List<dynamic>?)
        ?.map((e) => ItemTidakRestok.fromJson(Map<String, dynamic>.from(e)))
        .toList() ?? [];

    DateTime? timestamp;
    if (json['timestamp'] != null) {
      timestamp = (json['timestamp']).toDate();
    }

    return ModelRekomendasi(
      daftarStokUlang: restockList,
      daftarTidakStokUlang: tidakRestockList,
      tanggalDibuat: timestamp,
    );
  }
}
