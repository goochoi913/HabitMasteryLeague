import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2563EB);    // Blue
  static const Color secondary = Color(0xFF16A34A);  // Green
  static const Color accent = Color(0xFFF59E0B);     // Amber
  static const Color error = Color(0xFFDC2626);      // Red

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0F172A);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);

  static const Map<String, Color> categories = {
    'Health': Color(0xFF10B981),
    'Study': Color(0xFF6366F1),
    'Fitness': Color(0xFFF97316),
    'Mindfulness': Color(0xFF8B5CF6),
    'Other': Color(0xFF64748B),
  };
}