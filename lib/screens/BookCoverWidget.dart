import 'package:flutter/material.dart';


import '../models/livre.dart';


class BookCoverWidget extends StatelessWidget {
  final Livre livre;
  final double width;
  final double height;

  const BookCoverWidget({
    Key? key,
    required this.livre,
    this.width = 120,
    this.height = 180,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade300,
      ),
      clipBehavior: Clip.hardEdge,
      child: livre.couvertureUrl != null
          ? Image.network(
        livre.couvertureUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder();
        },
      )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Center(
      child: Icon(
        Icons.book,
        size: 40,
        color: Colors.grey.shade600,
      ),
    );
  }
}
