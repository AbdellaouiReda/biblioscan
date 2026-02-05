import 'package:flutter/material.dart';
import '../../services/tuto_service.dart';
import 'feature_overlay.dart';

class TutoWrapper extends StatefulWidget {
  final Widget child;
  final String tutoKey;
  final String title;
  final String description;

  const TutoWrapper({
    super.key,
    required this.child,
    required this.tutoKey,
    required this.title,
    required this.description,
  });

  @override
  State<TutoWrapper> createState() => _TutoWrapperState();
}

class _TutoWrapperState extends State<TutoWrapper> {
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _checkTuto();
  }

  void _checkTuto() async {
    // 🔹 LOGIQUE : On vérifie si l'utilisateur a coché "Ne plus afficher" par le passé
    bool alreadySeen = await TutoService.isPermanentlyHidden(widget.tutoKey);

    if (mounted) {
      setState(() {
        // Si PAS encore masqué définitivement -> On affiche
        _showOverlay = !alreadySeen;
      });
    }
  }

  void _handleDismiss(bool shouldHidePermanently) async {
    if (shouldHidePermanently) {
      // 🔹 Si la checkbox était cochée, on enregistre dans le téléphone
      await TutoService.markAsPermanentlyHidden(widget.tutoKey);
    }
    setState(() => _showOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          if (_showOverlay)
            FeatureOverlay(
              title: widget.title,
              description: widget.description,
              onDismiss: _handleDismiss,
            ),
        ],
      ),
    );
  }
}