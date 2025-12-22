import 'package:flutter/material.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';

class RiskIndicator extends StatelessWidget {
  final RiskLevel riskLevel;
  final double size;
  final bool showLabel;

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
            color: color.withValues(alpha: 0.15),
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

class RiskBadge extends StatelessWidget {
  final RiskLevel riskLevel;
  final bool compact;

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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 4 : 8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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

class RiskMeter extends StatelessWidget {
  final RiskLevel riskLevel;

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
                    color: isActive ? levelColor : levelColor.withValues(alpha: 0.2),
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