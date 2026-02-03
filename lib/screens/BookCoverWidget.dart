import 'package:flutter/material.dart';
import '../models/livre.dart';

class BookCoverWidget extends StatelessWidget {
  final Livre livre;

  const BookCoverWidget({
    super.key,
    required this.livre,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: livre.couvertureUrl != null
            ? Image.network(
          livre.couvertureUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(),
        )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(
          Icons.menu_book,
          size: 40,
          color: Colors.grey,
        ),
      ),
    );
  }
}
