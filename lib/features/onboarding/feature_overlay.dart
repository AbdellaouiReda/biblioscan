import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class FeatureOverlay extends StatefulWidget {
  final String title;
  final String description;
  final Function(bool) onDismiss; // Envoie l'info si la case est cochée

  const FeatureOverlay({
    super.key,
    required this.title,
    required this.description,
    required this.onDismiss,
  });

  @override
  State<FeatureOverlay> createState() => _FeatureOverlayState();
}

class _FeatureOverlayState extends State<FeatureOverlay> {
  bool _dontShowAgain = false; // État de la checkbox

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.85),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.help_outline, color: AppColors.secondary, size: 70),
              const SizedBox(height: 25),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTextStyles.title.copyWith(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 15),
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: AppTextStyles.subtitle.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 40),

              // --- LA CHECKBOX ---
              Theme(
                data: ThemeData(unselectedWidgetColor: Colors.white70),
                child: CheckboxListTile(
                  title: const Text(
                    "Ne plus afficher ce guide",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: _dontShowAgain,
                  activeColor: AppColors.secondary,
                  checkColor: Colors.black,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool? value) {
                    setState(() => _dontShowAgain = value ?? false);
                  },
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppButtonStyles.elevated,
                  onPressed: () => widget.onDismiss(_dontShowAgain),
                  child: const Text("J'AI COMPPRIS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}