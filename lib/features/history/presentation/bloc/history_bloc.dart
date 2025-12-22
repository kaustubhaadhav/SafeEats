import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/delete_scan.dart';
import '../../domain/usecases/get_scan_history.dart';
import 'history_event.dart';
import 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetScanHistory getScanHistory;
  final DeleteScan deleteScan;

  HistoryBloc({
    required this.getScanHistory,
    required this.deleteScan,
  }) : super(const HistoryState()) {
    on<LoadHistoryEvent>(_onLoadHistory);
    on<LoadMoreHistoryEvent>(_onLoadMoreHistory);
    on<DeleteScanEvent>(_onDeleteScan);
    on<RefreshHistoryEvent>(_onRefreshHistory);
  }

  Future<void> _onLoadHistory(
    LoadHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    emit(state.copyWith(status: HistoryStatus.loading));

    final result = await getScanHistory();

    result.fold(
      (failure) => emit(state.copyWith(
        status: HistoryStatus.error,
        errorMessage: failure.message,
      )),
      (scans) => emit(state.copyWith(
        status: HistoryStatus.loaded,
        scans: scans,
        hasReachedMax: scans.length < event.limit,
        currentPage: 0,
      )),
    );
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    if (state.hasReachedMax) return;

    emit(state.copyWith(status: HistoryStatus.loadingMore));

    final result = await getScanHistory();

    result.fold(
      (failure) => emit(state.copyWith(
        status: HistoryStatus.loaded,
        errorMessage: failure.message,
      )),
      (newScans) {
        // For simplified version, just replace all scans
        emit(state.copyWith(
          status: HistoryStatus.loaded,
          scans: newScans,
          hasReachedMax: true,
        ));
      },
    );
  }

  Future<void> _onDeleteScan(
    DeleteScanEvent event,
    Emitter<HistoryState> emit,
  ) async {
    final result = await deleteScan(event.scanId);

    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) {
        final updatedScans = state.scans
            .where((scan) => scan.id != event.scanId)
            .toList();
        emit(state.copyWith(scans: updatedScans));
      },
    );
  }

  Future<void> _onRefreshHistory(
    RefreshHistoryEvent event,
    Emitter<HistoryState> emit,
  ) async {
    add(const LoadHistoryEvent());
  }
}