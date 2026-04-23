import 'package:flutter/material.dart';

class TripTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const TripTile({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.map),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
