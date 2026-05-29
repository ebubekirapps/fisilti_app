import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imagePath;
  final double radius;

  const UserAvatar({
    super.key,
    required this.imagePath,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white12,
      child: Icon(
        Icons.person,
        size: radius,
        color: Colors.white,
      ),
    );
  }
}