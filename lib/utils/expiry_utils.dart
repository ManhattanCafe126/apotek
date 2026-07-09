import 'package:flutter/material.dart';

class UtilitasKadaluarsa {
  static DateTime parseExpDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime(9999);
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return DateTime(9999);
  }

  static int getDaysUntilExpiry(String expDateStr) {
    if (expDateStr.isEmpty) return 999;
    try {
      final expDate = parseExpDate(expDateStr);
      return expDate.difference(DateTime.now()).inDays;
    } catch (e) {
      debugPrint('Error calculating days: $e');
      return 999;
    }
  }

  static String getExpiryStatus(String expDateStr) {
    if (expDateStr.isEmpty) return 'Unknown';

    final daysLeft = getDaysUntilExpiry(expDateStr);

    if (daysLeft < 0) {
      return 'Kadaluarsa';
    } else if (daysLeft < 180) {
      return 'Waspada';
    } else {
      return 'Aman';
    }
  }

  static Color getStatusColor(String status) {
    switch (status) {
      case 'Kadaluarsa':
        return const Color(0xFFF44336);
      case 'Waspada':
        return const Color(0xFFFF9800);
      case 'Aman':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  static Color getStatusBackgroundColor(String status) {
    switch (status) {
      case 'Kadaluarsa':
        return const Color(0xFFFFEBEE);
      case 'Waspada':
        return const Color(0xFFFFF3E0);
      case 'Aman':
        return const Color(0xFFE8F5E9);
      default:
        return Colors.grey[100]!;
    }
  }

  static String formatDaysLeft(int daysLeft) {
    if (daysLeft < 0) {
      return '${(-daysLeft).abs()} hari lalu';
    } else if (daysLeft == 0) {
      return 'Hari ini';
    } else if (daysLeft == 1) {
      return '1 hari';
    } else if (daysLeft <= 30) {
      return '$daysLeft hari';
    } else if (daysLeft <= 180) {
      final months = (daysLeft / 30).round();
      return '$months bulan';
    } else {
      final years = (daysLeft / 365).round();
      return '$years tahun';
    }
  }

  static bool isExpired(String expDateStr) {
    if (expDateStr.isEmpty) return false;
    return getDaysUntilExpiry(expDateStr) < 0;
  }

  static bool needsWarning(String expDateStr) {
    if (expDateStr.isEmpty) return false;
    final daysLeft = getDaysUntilExpiry(expDateStr);
    return daysLeft >= 0 && daysLeft < 180;
  }
}
