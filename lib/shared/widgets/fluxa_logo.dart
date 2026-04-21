import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class FluxaLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool darkBackground;

  const FluxaLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.darkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          Text(
            'Fluxa',
            style: GoogleFonts.inter(
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              color: darkBackground ? Colors.white : AppColors.textPrimary,
              letterSpacing: -1.2,
            ),
          ),
          SizedBox(height: size * 0.04),
          Text(
            'Economia circular inteligente',
            style: GoogleFonts.inter(
              fontSize: size * 0.16,
              color: darkBackground
                  ? Colors.white.withOpacity(0.65)
                  : AppColors.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ],
    );
  }
}
