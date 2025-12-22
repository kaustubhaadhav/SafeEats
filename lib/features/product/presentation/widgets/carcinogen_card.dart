import 'package:flutter/material.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';
import 'risk_indicator.dart';

class CarcinogenCard extends StatelessWidget {
  final Carcinogen carcinogen;
  final String matchedIngredient;
  final double confidence;

  const CarcinogenCard({
    super.key,
    required this.carcinogen,
    required this.matchedIngredient,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(carcinogen.riskLevel.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Risk Badge
                  RiskBadge(riskLevel: carcinogen.riskLevel, compact: true),
                  const SizedBox(width: 12),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carcinogen.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.link,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Matched: $matchedIngredient',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              
              // Additional Info
              const SizedBox(height: 12),
              _InfoRow(
                label: 'Source',
                value: carcinogen.sourceShortName,
                icon: Icons.source,
              ),
              if (carcinogen.classification != null)
                _InfoRow(
                  label: 'Classification',
                  value: carcinogen.classification!,
                  icon: Icons.category,
                ),
              _InfoRow(
                label: 'Match Confidence',
                value: '${(confidence * 100).toStringAsFixed(0)}%',
                icon: Icons.analytics,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CarcinogenDetailsSheet(carcinogen: carcinogen),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarcinogenDetailsSheet extends StatelessWidget {
  final Carcinogen carcinogen;

  const _CarcinogenDetailsSheet({required this.carcinogen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Risk Indicator
                Center(
                  child: RiskIndicator(
                    riskLevel: carcinogen.riskLevel,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                Center(
                  child: Text(
                    carcinogen.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                // Info Cards
                _DetailCard(
                  title: 'Source',
                  content: carcinogen.sourceName,
                  icon: Icons.source,
                ),
                if (carcinogen.classification != null)
                  _DetailCard(
                    title: 'Classification',
                    content: _getIarcDescription(carcinogen.classification!),
                    icon: Icons.category,
                  ),
                _DetailCard(
                  title: 'Description',
                  content: carcinogen.description,
                  icon: Icons.info,
                ),
                if (carcinogen.aliases.isNotEmpty)
                  _DetailCard(
                    title: 'Also Known As',
                    content: carcinogen.aliases.join(', '),
                    icon: Icons.label,
                  ),
                if (carcinogen.commonFoods.isNotEmpty)
                  _DetailCard(
                    title: 'Commonly Found In',
                    content: carcinogen.commonFoods.join(', '),
                    icon: Icons.shopping_basket,
                  ),

                const SizedBox(height: 16),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This information is for educational purposes. '
                          'Consult healthcare professionals for medical advice.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getIarcDescription(String group) {
    switch (group) {
      case 'Group 1':
        return 'Group 1 - Carcinogenic to humans';
      case 'Group 2A':
        return 'Group 2A - Probably carcinogenic to humans';
      case 'Group 2B':
        return 'Group 2B - Possibly carcinogenic to humans';
      case 'Group 3':
        return 'Group 3 - Not classifiable as to carcinogenicity';
      default:
        return group;
    }
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _DetailCard({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}