import 'package:flutter/material.dart';
import '../utils/design_system.dart';
import '../utils/responsive_utils.dart';
import 'animations.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color; // kept for future variants or fallback
  final String? semanticHint;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    // Constrain width per spec (never full-width on Home)
    final maxWidth = context.isDesktop ? 320.0 : 400.0;
    final height = context.buttonHeight; // compact 44–48 on mobile/tablet

    // Gradient CTA per spec (#3B7FBF → #2C5F8F)
    const gradient = LinearGradient(
      colors: [Color(0xFF3B7FBF), Color(0xFF2C5F8F)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Semantics(
      label: 'Action: $label',
      hint: semanticHint ?? 'Tap to ${label.toLowerCase()}',
      button: true,
      enabled: true,
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            minHeight: height,
          ),
          child: SizedBox(
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(BorderRadiusSystem.medium),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x403B7FBF),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BorderRadiusSystem.medium),
                child: ScaleAnimation(
                  scaleFactor: 0.95,
                  duration: const Duration(milliseconds: 100),
                  child: ElevatedButton.icon(
                    onPressed: onPressed,
                    icon: Icon(icon, size: 18),
                    label: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      // Transparent to show gradient container decoration
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      minimumSize: Size.fromHeight(height),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          BorderRadiusSystem.medium,
                        ),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
