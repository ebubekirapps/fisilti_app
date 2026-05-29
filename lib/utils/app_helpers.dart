import 'dart:io';
import 'package:flutter/material.dart';
Color genderBaseColor(String? gender) {
  switch (gender) {
    case "Kadın":
      return const Color(0xFFD96A96);
    case "Erkek":
      return const Color(0xFF5C8DDA);
    default:
      return const Color(0xFF7A7288);
  }
}

BoxDecoration genderCardDecoration(
  String? gender, {
  double opacity = 0.22,
  double radius = 24,
}) {
  final base = genderBaseColor(gender);
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [
        base.withOpacity(opacity + 0.06),
        base.withOpacity(opacity - 0.02),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: base.withOpacity(0.18)),
  );
}

ImageProvider? fileImageProvider(String? path) {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return FileImage(file);
}