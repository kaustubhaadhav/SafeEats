import 'package:equatable/equatable.dart';

abstract class CarcinogenEvent extends Equatable {
  const CarcinogenEvent();

  @override
  List<Object?> get props => [];
}

class LoadCarcinogensEvent extends CarcinogenEvent {
  const LoadCarcinogensEvent();
}

class SearchCarcinogensEvent extends CarcinogenEvent {
  final String query;

  const SearchCarcinogensEvent({required this.query});

  @override
  List<Object> get props => [query];
}

class FilterByRiskLevelEvent extends CarcinogenEvent {
  final int? riskLevelValue;

  const FilterByRiskLevelEvent({this.riskLevelValue});

  @override
  List<Object?> get props => [riskLevelValue];
}

class FilterBySourceEvent extends CarcinogenEvent {
  final String? source;

  const FilterBySourceEvent({this.source});

  @override
  List<Object?> get props => [source];
}

class ClearFiltersEvent extends CarcinogenEvent {
  const ClearFiltersEvent();
}