import 'package:equatable/equatable.dart';
import '../../domain/entities/carcinogen.dart';

enum CarcinogenStatus {
  initial,
  loading,
  loaded,
  error,
}

class CarcinogenState extends Equatable {
  final CarcinogenStatus status;
  final List<Carcinogen> allCarcinogens;
  final List<Carcinogen> filteredCarcinogens;
  final String searchQuery;
  final int? riskLevelFilter;
  final String? sourceFilter;
  final String? errorMessage;

  const CarcinogenState({
    this.status = CarcinogenStatus.initial,
    this.allCarcinogens = const [],
    this.filteredCarcinogens = const [],
    this.searchQuery = '',
    this.riskLevelFilter,
    this.sourceFilter,
    this.errorMessage,
  });

  bool get hasFilters =>
      searchQuery.isNotEmpty ||
      riskLevelFilter != null ||
      sourceFilter != null;

  int get totalCount => allCarcinogens.length;
  int get filteredCount => filteredCarcinogens.length;

  Map<RiskLevel, int> get countByRiskLevel {
    final counts = <RiskLevel, int>{};
    for (final carcinogen in allCarcinogens) {
      counts[carcinogen.riskLevel] = (counts[carcinogen.riskLevel] ?? 0) + 1;
    }
    return counts;
  }

  Set<String> get availableSources {
    return allCarcinogens.map((c) => c.sourceShortName).toSet();
  }

  CarcinogenState copyWith({
    CarcinogenStatus? status,
    List<Carcinogen>? allCarcinogens,
    List<Carcinogen>? filteredCarcinogens,
    String? searchQuery,
    int? riskLevelFilter,
    String? sourceFilter,
    String? errorMessage,
    bool clearRiskLevelFilter = false,
    bool clearSourceFilter = false,
  }) {
    return CarcinogenState(
      status: status ?? this.status,
      allCarcinogens: allCarcinogens ?? this.allCarcinogens,
      filteredCarcinogens: filteredCarcinogens ?? this.filteredCarcinogens,
      searchQuery: searchQuery ?? this.searchQuery,
      riskLevelFilter: clearRiskLevelFilter ? null : (riskLevelFilter ?? this.riskLevelFilter),
      sourceFilter: clearSourceFilter ? null : (sourceFilter ?? this.sourceFilter),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        allCarcinogens,
        filteredCarcinogens,
        searchQuery,
        riskLevelFilter,
        sourceFilter,
        errorMessage,
      ];
}