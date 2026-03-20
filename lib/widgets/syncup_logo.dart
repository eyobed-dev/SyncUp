import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/sync_up_theme.dart';

/// Creative SyncUp logo with icon on the side.
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
    final iconSize = size * 0.85;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: SyncUpTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.sync_alt_rounded,
            size: iconSize,
            color: SyncUpTheme.primary,
          ),
        ),
        SizedBox(width: size * 0.4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Sync',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w800,
                      color: SyncUpTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Up',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: SyncUpTheme.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            if (!compact)
              Container(
                width: 28,
                height: 2,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: SyncUpTheme.primary.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
