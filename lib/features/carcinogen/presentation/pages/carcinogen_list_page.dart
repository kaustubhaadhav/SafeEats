import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/carcinogen.dart';
import '../../../product/presentation/widgets/risk_indicator.dart';
import '../bloc/carcinogen_bloc.dart';
import '../bloc/carcinogen_event.dart';
import '../bloc/carcinogen_state.dart';

class CarcinogenListPage extends StatefulWidget {
  const CarcinogenListPage({super.key});

  @override
  State<CarcinogenListPage> createState() => _CarcinogenListPageState();
}

class _CarcinogenListPageState extends State<CarcinogenListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<CarcinogenBloc>().add(const LoadCarcinogensEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carcinogen Database'),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search carcinogens...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: BlocBuilder<CarcinogenBloc, CarcinogenState>(
                  builder: (context, state) {
                    if (state.searchQuery.isNotEmpty) {
                      return IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<CarcinogenBloc>().add(
                                const SearchCarcinogensEvent(query: ''),
                              );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                context.read<CarcinogenBloc>().add(
                      SearchCarcinogensEvent(query: value),
                    );
              },
            ),
          ),

          // Filters
          _FilterChips(),

          // List
          Expanded(
            child: BlocBuilder<CarcinogenBloc, CarcinogenState>(
              builder: (context, state) {
                switch (state.status) {
                  case CarcinogenStatus.initial:
                  case CarcinogenStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case CarcinogenStatus.error:
                    return _ErrorView(
                      message: state.errorMessage ?? 'Failed to load',
                      onRetry: () {
                        context
                            .read<CarcinogenBloc>()
                            .add(const LoadCarcinogensEvent());
                      },
                    );

                  case CarcinogenStatus.loaded:
                    if (state.filteredCarcinogens.isEmpty) {
                      return _EmptySearchView(
                        hasFilters: state.hasFilters,
                        onClearFilters: () {
                          _searchController.clear();
                          context
                              .read<CarcinogenBloc>()
                              .add(const ClearFiltersEvent());
                        },
                      );
                    }
                    return _CarcinogenList(
                      carcinogens: state.filteredCarcinogens,
                      totalCount: state.totalCount,
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarcinogenBloc, CarcinogenState>(
      builder: (context, state) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Risk Level Filter
              _FilterDropdown<int?>(
                label: 'Risk Level',
                value: state.riskLevelFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Levels')),
                  ...RiskLevel.values.map(
                    (level) => DropdownMenuItem(
                      value: level.value,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Color(level.color),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(level.label),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  context.read<CarcinogenBloc>().add(
                        FilterByRiskLevelEvent(riskLevelValue: value),
                      );
                },
              ),
              const SizedBox(width: 12),

              // Source Filter
              _FilterDropdown<String?>(
                label: 'Source',
                value: state.sourceFilter,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Sources')),
                  ...state.availableSources.map(
                    (source) => DropdownMenuItem(
                      value: source,
                      child: Text(source),
                    ),
                  ),
                ],
                onChanged: (value) {
                  context.read<CarcinogenBloc>().add(
                        FilterBySourceEvent(source: value),
                      );
                },
              ),

              // Clear Filters
              if (state.hasFilters) ...[
                const SizedBox(width: 12),
                ActionChip(
                  avatar: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear'),
                  onPressed: () {
                    context.read<CarcinogenBloc>().add(const ClearFiltersEvent());
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isDense: true,
          hint: Text(label),
        ),
      ),
    );
  }
}

class _CarcinogenList extends StatelessWidget {
  final List<Carcinogen> carcinogens;
  final int totalCount;

  const _CarcinogenList({
    required this.carcinogens,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Showing ${carcinogens.length} of $totalCount entries',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: carcinogens.length,
            itemBuilder: (context, index) {
              return _CarcinogenListTile(carcinogen: carcinogens[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _CarcinogenListTile extends StatelessWidget {
  final Carcinogen carcinogen;

  const _CarcinogenListTile({required this.carcinogen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(carcinogen.riskLevel.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Risk Indicator
              Container(
                width: 8,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carcinogen.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RiskBadge(
                          riskLevel: carcinogen.riskLevel,
                          compact: true,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            carcinogen.sourceShortName,
                            style: theme.textTheme.bodySmall,
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

                // Details
                _DetailSection(
                  icon: Icons.source,
                  title: 'Source',
                  content: carcinogen.sourceName,
                ),
                if (carcinogen.classification != null)
                  _DetailSection(
                    icon: Icons.category,
                    title: 'Classification',
                    content: _getIarcDescription(carcinogen.classification!),
                  ),
                _DetailSection(
                  icon: Icons.info,
                  title: 'Description',
                  content: carcinogen.description,
                ),
                if (carcinogen.aliases.isNotEmpty)
                  _DetailSection(
                    icon: Icons.label,
                    title: 'Also Known As',
                    content: carcinogen.aliases.join(', '),
                  ),
                if (carcinogen.commonFoods.isNotEmpty)
                  _DetailSection(
                    icon: Icons.shopping_basket,
                    title: 'Commonly Found In',
                    content: carcinogen.commonFoods.join(', '),
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
        return 'Group 1 - Carcinogenic to humans (sufficient evidence)';
      case 'Group 2A':
        return 'Group 2A - Probably carcinogenic to humans (limited evidence in humans, sufficient in animals)';
      case 'Group 2B':
        return 'Group 2B - Possibly carcinogenic to humans (limited evidence)';
      case 'Group 3':
        return 'Group 3 - Not classifiable as to carcinogenicity to humans';
      default:
        return group;
    }
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
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
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
          Text(content, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptySearchView extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptySearchView({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try adjusting your search or filters'
                  : 'No carcinogens match your search',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}