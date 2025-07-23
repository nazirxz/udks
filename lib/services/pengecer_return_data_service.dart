// lib/services/pengecer_return_data_service.dart
import 'package:flutter/material.dart';


class PengecerReturnDataService {
  static Map<String, dynamic>? _returnData;
  
  // Load return data (simulate API call)
  static Future<void> loadReturnData() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_returnData == null) {
      _returnData = {
        'return_submissions': [
          {
            'id': 1,
            'nama': 'Jonathan',
            'nama_distributor': 'Sikma Jaya',
            'email': 'jondoe@mymail.com',
            'nomor_telepon': '08893114262',
            'kode_pos': '28292',
            'ruas': 'Pekanbaru',
            'keterangan': 'Barang rusak karena digigit tikus',
            'tanggal_submit': '2024-01-15 10:30:00',
            'status': 'Pending',
            'foto_url': null,
          },
          {
            'id': 2,
            'nama': 'Siti Aminah',
            'nama_distributor': 'Maju Bersama',
            'email': 'siti.aminah@email.com',
            'nomor_telepon': '08123456789',
            'kode_pos': '28291',
            'ruas': 'Pekanbaru',
            'keterangan': 'Kemasan bocor dan isi tumpah',
            'tanggal_submit': '2024-01-14 14:20:00',
            'status': 'Approved',
            'foto_url': null,
          },
          {
            'id': 3,
            'nama': 'Budi Santoso',
            'nama_distributor': 'Toko Berkah',
            'email': 'budi.santoso@email.com',
            'nomor_telepon': '08987654321',
            'kode_pos': '28293',
            'ruas': 'Pekanbaru',
            'keterangan': 'Produk expired sebelum tanggal yang tertera',
            'tanggal_submit': '2024-01-13 09:15:00',
            'status': 'Rejected',
            'foto_url': null,
          },
        ],
        'return_statistics': {
          'total_submissions': 15,
          'pending_submissions': 8,
          'approved_submissions': 5,
          'rejected_submissions': 2,
          'total_value': 450000,
        },
        'common_reasons': [
          'Barang rusak',
          'Kemasan bocor',
          'Produk expired',
          'Digigit tikus',
          'Kualitas tidak sesuai',
          'Salah kirim produk',
        ],
      };
    }
  }

  // Submit new return request
  static Future<bool> submitReturnRequest({
    required String nama,
    required String namaDistributor,
    required String email,
    required String nomorTelepon,
    required String kodePo,
    required String ruas,
    required String keterangan,
    String? fotoUrl,
  }) async {
    try {
      await loadReturnData();
      
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final newSubmission = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'nama': nama,
        'nama_distributor': namaDistributor,
        'email': email,
        'nomor_telepon': nomorTelepon,
        'kode_pos': kodePo,
        'ruas': ruas,
        'keterangan': keterangan,
        'tanggal_submit': DateTime.now().toString(),
        'status': 'Pending',
        'foto_url': fotoUrl,
      };
      
      // Add to local data (in real app, this would be sent to server)
      final List<dynamic> submissions = _returnData?['return_submissions'] ?? [];
      submissions.insert(0, newSubmission);
      
      // Update statistics
      final stats = _returnData?['return_statistics'] as Map<String, dynamic>?;
      if (stats != null) {
        stats['total_submissions'] = (stats['total_submissions'] as int) + 1;
        stats['pending_submissions'] = (stats['pending_submissions'] as int) + 1;
      }
      
      return true;
    } catch (e) {
      print('Error submitting return request: $e');
      return false;
    }
  }

  // Get return submissions for current user
  static Future<List<Map<String, dynamic>>> getReturnSubmissions() async {
    await loadReturnData();
    final List<dynamic> data = _returnData?['return_submissions'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // Get return statistics
  static Future<Map<String, dynamic>> getReturnStatistics() async {
    await loadReturnData();
    return _returnData?['return_statistics'] ?? {};
  }

  // Get common return reasons
  static Future<List<String>> getCommonReasons() async {
    await loadReturnData();
    final List<dynamic> reasons = _returnData?['common_reasons'] ?? [];
    return reasons.cast<String>();
  }

  // Cancel return request (only if status is pending)
  static Future<bool> cancelReturnRequest(int id) async {
    try {
      await loadReturnData();
      final List<dynamic> submissions = _returnData?['return_submissions'] ?? [];
      
      final submissionIndex = submissions.indexWhere((item) => item['id'] == id);
      if (submissionIndex != -1) {
        final submission = submissions[submissionIndex];
        if (submission['status'] == 'Pending') {
          submissions.removeAt(submissionIndex);
          
          // Update statistics
          final stats = _returnData?['return_statistics'] as Map<String, dynamic>?;
          if (stats != null) {
            stats['total_submissions'] = (stats['total_submissions'] as int) - 1;
            stats['pending_submissions'] = (stats['pending_submissions'] as int) - 1;
          }
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error canceling return request: $e');
      return false;
    }
  }

  // Get return status color
  static getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get return status icon
  static getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.access_time;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Format return submission for display
  static String formatSubmissionDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} menit yang lalu';
        }
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} hari yang lalu';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }
}