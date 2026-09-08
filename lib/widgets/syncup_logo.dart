/*
 * Authors:
 *   Adar Otieno (xotiena00@vutbr.cz) - FIT VUT
 *   Eyobed Awel Nuri (xnuriey00@vutbr.cz) - FIT VUT
 *   Pengwei Jiang (xjiangp00@vutbr.cz) - FIT VUT
 *   Mengran Zhao (xzhaome00@vutbr.cz) - FIT VUT
 *
 * License: GPL
 *
 * Purpose: Reusable UI component for the syncup_logo interface.
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sync_up/theme/sync_up_colors.dart';

/// Shared SyncUp wordmark logo used across the app.
class SyncUpLogo extends StatelessWidget {
  final double size;
  final bool compact;

  const SyncUpLogo({
    super.key,
    this.size = 24,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize =
        (compact ? size * 0.66 : size * 0.72).clamp(16.0, 34.0).toDouble();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Sync',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                  letterSpacing: -0.45,
                ),
              ),
              TextSpan(
                text: 'Up',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: context.colors.primary,
                  letterSpacing: -0.35,
                ),
              ),
            ],
          ),
        ),
        if (!compact)
          Container(
            width: fontSize * 1.7,
            height: 2.2,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
