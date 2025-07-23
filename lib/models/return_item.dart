// lib/models/return_item.dart

class ReturnItem {
  final int? id;
  final int orderId;
  final String orderNumber;
  final int orderItemId;
  final int userId;
  final String namaBarang;
  final String kategoriBarang;
  final int jumlahBarang;
  final String? namaProdusen;
  final String alasanPengembalian;
  final String? fotoBukti;
  final String? fotoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;

  ReturnItem({
    this.id,
    required this.orderId,
    required this.orderNumber,
    required this.orderItemId,
    required this.userId,
    required this.namaBarang,
    required this.kategoriBarang,
    required this.jumlahBarang,
    this.namaProdusen,
    required this.alasanPengembalian,
    this.fotoBukti,
    this.fotoUrl,
    this.createdAt,
    this.updatedAt,
    this.status,
  });

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    // Debug logging untuk melihat data yang masuk
    print('DEBUG: Creating ReturnItem from JSON: $json');
    print('DEBUG: order_id value: ${json['order_id']} (${json['order_id'].runtimeType})');
    print('DEBUG: jumlah_barang value: ${json['jumlah_barang']} (${json['jumlah_barang'].runtimeType})');
    
    try {
      return ReturnItem(
        id: _parseIntFromDynamic(json['id']),
        orderId: _parseIntFromDynamic(json['order_id']) ?? 0,
        orderNumber: json['order_number']?.toString() ?? '',
        orderItemId: _parseIntFromDynamic(json['order_item_id']) ?? 0,
        userId: _parseIntFromDynamic(json['user_id']) ?? 0,
        namaBarang: json['nama_barang']?.toString() ?? '',
        kategoriBarang: json['kategori_barang']?.toString() ?? '',
        jumlahBarang: _parseIntFromDynamic(json['jumlah_barang']) ?? 0,
        namaProdusen: json['nama_produsen']?.toString(),
        alasanPengembalian: json['alasan_pengembalian']?.toString() ?? '',
        fotoBukti: json['foto_bukti']?.toString(),
        fotoUrl: json['foto_url']?.toString(),
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
        status: json['status']?.toString(),
      );
    } catch (e) {
      print('DEBUG: Error in ReturnItem.fromJson: $e');
      rethrow;
    }
  }

  // Helper method to safely parse int from dynamic value
  static int? _parseIntFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'order_number': orderNumber,
      'order_item_id': orderItemId,
      'user_id': userId,
      'nama_barang': namaBarang,
      'kategori_barang': kategoriBarang,
      'jumlah_barang': jumlahBarang,
      'nama_produsen': namaProdusen,
      'alasan_pengembalian': alasanPengembalian,
      'foto_bukti': fotoBukti,
      'foto_url': fotoUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'status': status,
    };
  }

  String get formattedDate {
    if (createdAt == null) return '';
    final date = createdAt!;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Menunggu Review';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'processing':
        return 'Sedang Diproses';
      case 'completed':
        return 'Selesai';
      default:
        return status ?? 'Unknown';
    }
  }
}
