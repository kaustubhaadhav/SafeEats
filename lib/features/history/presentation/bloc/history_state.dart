import 'package:equatable/equatable.dart';
import '../../domain/entities/scan_history.dart';

enum HistoryStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  error,
}

class HistoryState extends Equatable {
  final HistoryStatus status;
  final List<ScanHistory> scans;
  final bool hasReachedMax;
  final String? errorMessage;
  final int currentPage;
  static const int pageSize = 50;

  const HistoryState({
    this.status = HistoryStatus.initial,
    this.scans = const [],
    this.hasReachedMax = false,
    this.errorMessage,
    this.currentPage = 0,
  });

  bool get isEmpty => scans.isEmpty && status == HistoryStatus.loaded;
  int get totalScans => scans.length;

  HistoryState copyWith({
    HistoryStatus? status,
    List<ScanHistory>? scans,
    bool? hasReachedMax,
    String? errorMessage,
    int? currentPage,
  }) {
    return HistoryState(
      status: status ?? this.status,
      scans: scans ?? this.scans,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage ?? this.errorMessage,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        scans,
        hasReachedMax,
        errorMessage,
        currentPage,
      ];
}