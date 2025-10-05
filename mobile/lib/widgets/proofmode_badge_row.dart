// ABOUTME: Reusable row of ProofMode and Vine badges for consistent display across video UI
// ABOUTME: Automatically shows appropriate badges based on VideoEvent metadata

import 'package:flutter/material.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/widgets/proofmode_badge.dart';
import 'package:openvine/utils/proofmode_helpers.dart';

/// Reusable badge row for displaying ProofMode verification and Vine badges
class ProofModeBadgeRow extends StatelessWidget {
  const ProofModeBadgeRow({
    super.key,
    required this.video,
    this.size = BadgeSize.small,
    this.spacing = 8.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final VideoEvent video;
  final BadgeSize size;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    // Don't render anything if no badges to show
    if (!video.shouldShowProofModeBadge && !video.shouldShowVineBadge) {
      return const SizedBox.shrink();
    }

    final badges = <Widget>[];

    // Add ProofMode badge if applicable
    if (video.shouldShowProofModeBadge) {
      badges.add(
        ProofModeBadge(
          level: video.getVerificationLevel(),
          size: size,
        ),
      );
    }

    // Add Original Vine badge if applicable
    if (video.shouldShowVineBadge) {
      badges.add(
        OriginalVineBadge(
          size: size,
        ),
      );
    }

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.start,
      children: badges,
    );
  }
}
