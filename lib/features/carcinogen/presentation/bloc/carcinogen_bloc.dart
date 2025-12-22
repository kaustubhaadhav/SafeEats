import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/carcinogen.dart';
import '../../domain/usecases/get_all_carcinogens.dart';
import 'carcinogen_event.dart';
import 'carcinogen_state.dart';

class CarcinogenBloc extends Bloc<CarcinogenEvent, CarcinogenState> {
  final GetAllCarcinogens getAllCarcinogens;

  CarcinogenBloc({required this.getAllCarcinogens})
      : super(const CarcinogenState()) {
    on<LoadCarcinogensEvent>(_onLoadCarcinogens);
    on<SearchCarcinogensEvent>(_onSearchCarcinogens);
    on<FilterByRiskLevelEvent>(_onFilterByRiskLevel);
    on<FilterBySourceEvent>(_onFilterBySource);
    on<ClearFiltersEvent>(_onClearFilters);
  }

  Future<void> _onLoadCarcinogens(
    LoadCarcinogensEvent event,
    Emitter<CarcinogenState> emit,
  ) async {
    emit(state.copyWith(status: CarcinogenStatus.loading));

    final result = await getAllCarcinogens();

    result.fold(
      (failure) => emit(state.copyWith(
        status: CarcinogenStatus.error,
        errorMessage: failure.message,
      )),
      (carcinogens) => emit(state.copyWith(
        status: CarcinogenStatus.loaded,
        allCarcinogens: carcinogens,
        filteredCarcinogens: carcinogens,
      )),
    );
  }

  void _onSearchCarcinogens(
    SearchCarcinogensEvent event,
    Emitter<CarcinogenState> emit,
  ) {
    final query = event.query.toLowerCase().trim();
    
    emit(state.copyWith(
      searchQuery: query,
      filteredCarcinogens: _applyFilters(
        state.allCarcinogens,
        searchQuery: query,
        riskLevelFilter: state.riskLevelFilter,
        sourceFilter: state.sourceFilter,
      ),
    ));
  }

  void _onFilterByRiskLevel(
    FilterByRiskLevelEvent event,
    Emitter<CarcinogenState> emit,
  ) {
    emit(state.copyWith(
      riskLevelFilter: event.riskLevelValue,
      clearRiskLevelFilter: event.riskLevelValue == null,
      filteredCarcinogens: _applyFilters(
        state.allCarcinogens,
        searchQuery: state.searchQuery,
        riskLevelFilter: event.riskLevelValue,
        sourceFilter: state.sourceFilter,
      ),
    ));
  }

  void _onFilterBySource(
    FilterBySourceEvent event,
    Emitter<CarcinogenState> emit,
  ) {
    emit(state.copyWith(
      sourceFilter: event.source,
      clearSourceFilter: event.source == null,
      filteredCarcinogens: _applyFilters(
        state.allCarcinogens,
        searchQuery: state.searchQuery,
        riskLevelFilter: state.riskLevelFilter,
        sourceFilter: event.source,
      ),
    ));
  }

  void _onClearFilters(
    ClearFiltersEvent event,
    Emitter<CarcinogenState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: '',
      clearRiskLevelFilter: true,
      clearSourceFilter: true,
      filteredCarcinogens: state.allCarcinogens,
    ));
  }

  List<Carcinogen> _applyFilters(
    List<Carcinogen> carcinogens, {
    required String searchQuery,
    required int? riskLevelFilter,
    required String? sourceFilter,
  }) {
    return carcinogens.where((carcinogen) {
      // Search filter
      if (searchQuery.isNotEmpty) {
        final matchesName = carcinogen.name.toLowerCase().contains(searchQuery);
        final matchesAliases = carcinogen.aliases
            .any((alias) => alias.toLowerCase().contains(searchQuery));
        final matchesDescription =
            carcinogen.description.toLowerCase().contains(searchQuery);
        
        if (!matchesName && !matchesAliases && !matchesDescription) {
          return false;
        }
      }

      // Risk level filter
      if (riskLevelFilter != null &&
          carcinogen.riskLevel.value != riskLevelFilter) {
        return false;
      }

      // Source filter
      if (sourceFilter != null && carcinogen.sourceShortName != sourceFilter) {
        return false;
      }

      return true;
    }).toList();
  }
}