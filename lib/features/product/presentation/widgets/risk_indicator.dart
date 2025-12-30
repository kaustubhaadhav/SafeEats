import 'package:flutter/material.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';

/// A circular indicator displaying the carcinogen risk level.
///
/// This widget provides a visual representation of the risk associated
/// with detected carcinogens in a product. It displays an icon within
/// a colored circle, with an optional label below.
///
/// ## Example
///
/// ```dart
/// RiskIndicator(
///   riskLevel: RiskLevel.high,
///   size: 80,
///   showLabel: true,
/// )
/// ```
///
/// The colors and icons are automatically determined based on [riskLevel]:
/// - Safe: Green checkmark
/// - Low: Blue info icon
/// - Medium: Yellow/amber warning
/// - High: Orange error icon
/// - Critical: Red dangerous icon
///
/// See also:
/// - [RiskBadge] for a compact inline badge
/// - [RiskMeter] for a horizontal meter display
class RiskIndicator extends StatelessWidget {
  /// The risk level to display.
  final RiskLevel riskLevel;
  
  /// The diameter of the indicator circle in logical pixels.
  ///
  /// Defaults to 60.
  final double size;
  
  /// Whether to show the risk level label below the indicator.
  ///
  /// Defaults to true.
  final bool showLabel;

  /// Creates a risk indicator widget.
  ///
  /// The [riskLevel] parameter is required and determines the color
  /// and icon displayed.
  const RiskIndicator({
    super.key,
    required this.riskLevel,
    this.size = 60,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(riskLevel.color);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 3,
            ),
          ),
          child: Center(
            child: _getIcon(color),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 8),
          Text(
            riskLevel.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ],
    );
  }

  Widget _getIcon(Color color) {
    IconData icon;
    double iconSize = size * 0.5;

    switch (riskLevel) {
      case RiskLevel.safe:
        icon = Icons.check_circle;
        break;
      case RiskLevel.low:
        icon = Icons.info;
        break;
      case RiskLevel.medium:
        icon = Icons.warning_amber;
        break;
      case RiskLevel.high:
        icon = Icons.error;
        break;
      case RiskLevel.critical:
        icon = Icons.dangerous;
        break;
    }

    return Icon(
      icon,
      size: iconSize,
      color: color,
    );
  }
}

/// A compact badge displaying the risk level as an inline chip.
///
/// This widget is useful for displaying risk information in lists,
/// cards, or other space-constrained layouts. It shows an icon
/// and label in a colored container.
///
/// ## Example
///
/// ```dart
/// // Full size badge
/// RiskBadge(riskLevel: RiskLevel.medium)
///
/// // Compact badge for tight spaces
/// RiskBadge(riskLevel: RiskLevel.high, compact: true)
/// ```
///
/// See also:
/// - [RiskIndicator] for a larger circular indicator
/// - [RiskMeter] for a horizontal meter display
class RiskBadge extends StatelessWidget {
  /// The risk level to display.
  final RiskLevel riskLevel;
  
  /// Whether to use a compact layout with smaller text and padding.
  ///
  /// Defaults to false.
  final bool compact;

  /// Creates a risk badge widget.
  const RiskBadge({
    super.key,
    required this.riskLevel,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(riskLevel.color);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconData(),
            size: compact ? 14 : 18,
            color: color,
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(
            riskLevel.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconData() {
    switch (riskLevel) {
      case RiskLevel.safe:
        return Icons.check_circle;
      case RiskLevel.low:
        return Icons.info;
      case RiskLevel.medium:
        return Icons.warning_amber;
      case RiskLevel.high:
        return Icons.error;
      case RiskLevel.critical:
        return Icons.dangerous;
    }
  }
}

/// A horizontal meter showing the risk level with all levels visible.
///
/// This widget displays a segmented bar where each segment represents
/// a risk level. Segments up to and including the current risk level
/// are highlighted, providing context for how severe the risk is.
///
/// ## Example
///
/// ```dart
/// RiskMeter(riskLevel: RiskLevel.medium)
/// ```
///
/// The meter shows 5 segments:
/// - Safe (green)
/// - Low (light green)
/// - Medium (yellow)
/// - High (orange)
/// - Critical (red)
///
/// See also:
/// - [RiskIndicator] for a circular indicator
/// - [RiskBadge] for a compact inline badge
class RiskMeter extends StatelessWidget {
  /// The current risk level to highlight on the meter.
  final RiskLevel riskLevel;

  /// Creates a risk meter widget.
  const RiskMeter({
    super.key,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Risk Level',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Text(
              riskLevel.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Color(riskLevel.color),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: RiskLevel.values.map((level) {
              final isActive = level.value <= riskLevel.value;
              final levelColor = Color(level.color);

              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(
                    right: level.value < RiskLevel.values.length - 1 ? 2 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? levelColor : levelColor.withOpacity(0.2),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}