import 'package:flutter/material.dart';

class ExpiryUtils {
  /// Parse expiry date from DD/MM/YYYY format to DateTime
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

  /// Get days remaining until expiry
  /// Positive = future, 0 = today, Negative = past/expired
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

  /// Get expiry status based on days remaining
  /// - "Kadaluarsa" (< 0 days)
  /// - "Waspada" (0-180 days)
  /// - "Aman" (>= 180 days)
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

  /// Get color for status
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Kadaluarsa':
        return const Color(0xFFF44336); // Red
      case 'Waspada':
        return const Color(0xFFFF9800); // Orange
      case 'Aman':
        return const Color(0xFF4CAF50); // Green
      default:
        return Colors.grey;
    }
  }

  /// Get status background color (lighter)
  static Color getStatusBackgroundColor(String status) {
    switch (status) {
      case 'Kadaluarsa':
        return const Color(0xFFFFEBEE); // Light red
      case 'Waspada':
        return const Color(0xFFFFF3E0); // Light orange
      case 'Aman':
        return const Color(0xFFE8F5E9); // Light green
      default:
        return Colors.grey[100]!;
    }
  }

  /// Format days left to readable string
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

  /// Check if drug is already expired
  static bool isExpired(String expDateStr) {
    if (expDateStr.isEmpty) return false;
    return getDaysUntilExpiry(expDateStr) < 0;
  }

  /// Check if drug needs warning (< 6 months)
  static bool needsWarning(String expDateStr) {
    if (expDateStr.isEmpty) return false;
    final daysLeft = getDaysUntilExpiry(expDateStr);
    return daysLeft >= 0 && daysLeft < 180;
  }
}
