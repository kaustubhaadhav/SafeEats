import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistoryEvent extends HistoryEvent {
  final int limit;
  final int offset;

  const LoadHistoryEvent({
    this.limit = 50,
    this.offset = 0,
  });

  @override
  List<Object> get props => [limit, offset];
}

class LoadMoreHistoryEvent extends HistoryEvent {
  const LoadMoreHistoryEvent();
}

class DeleteScanEvent extends HistoryEvent {
  final int scanId;

  const DeleteScanEvent({required this.scanId});

  @override
  List<Object> get props => [scanId];
}

class ClearHistoryEvent extends HistoryEvent {
  const ClearHistoryEvent();
}

class RefreshHistoryEvent extends HistoryEvent {
  const RefreshHistoryEvent();
}