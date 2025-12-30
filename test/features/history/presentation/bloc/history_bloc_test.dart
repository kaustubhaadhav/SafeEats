import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safeeats/core/errors/failures.dart';
import 'package:safeeats/features/carcinogen/domain/entities/carcinogen.dart';
import 'package:safeeats/features/history/domain/entities/scan_history.dart';
import 'package:safeeats/features/history/domain/usecases/delete_scan.dart';
import 'package:safeeats/features/history/domain/usecases/get_scan_history.dart';
import 'package:safeeats/features/history/presentation/bloc/history_bloc.dart';
import 'package:safeeats/features/history/presentation/bloc/history_event.dart';
import 'package:safeeats/features/history/presentation/bloc/history_state.dart';

class MockGetScanHistory extends Mock implements GetScanHistory {}

class MockDeleteScan extends Mock implements DeleteScan {}

void main() {
  late HistoryBloc bloc;
  late MockGetScanHistory mockGetScanHistory;
  late MockDeleteScan mockDeleteScan;

  setUp(() {
    mockGetScanHistory = MockGetScanHistory();
    mockDeleteScan = MockDeleteScan();
    bloc = HistoryBloc(
      getScanHistory: mockGetScanHistory,
      deleteScan: mockDeleteScan,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tScanHistory1 = ScanHistory(
    id: 1,
    barcode: '012345678905',
    productName: 'Test Product 1',
    brand: 'Test Brand 1',
    imageUrl: 'https://example.com/image1.jpg',
    ingredients: const ['Water', 'Sugar'],
    detectedCarcinogenIds: const [],
    overallRiskLevel: RiskLevel.safe,
    scannedAt: DateTime(2024, 1, 15, 10, 30),
  );

  final tScanHistory2 = ScanHistory(
    id: 2,
    barcode: '123456789012',
    productName: 'Test Product 2',
    brand: 'Test Brand 2',
    imageUrl: 'https://example.com/image2.jpg',
    ingredients: const ['Water', 'Formaldehyde'],
    detectedCarcinogenIds: const ['formaldehyde'],
    overallRiskLevel: RiskLevel.high,
    scannedAt: DateTime(2024, 1, 16, 14, 45),
  );

  final tScanHistory3 = ScanHistory(
    id: 3,
    barcode: '234567890123',
    productName: 'Test Product 3',
    brand: 'Test Brand 3',
    imageUrl: null,
    ingredients: const ['Water', 'Salt'],
    detectedCarcinogenIds: const [],
    overallRiskLevel: RiskLevel.safe,
    scannedAt: DateTime(2024, 1, 17, 9, 0),
  );

  final tScans = [tScanHistory1, tScanHistory2, tScanHistory3];

  group('HistoryBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, equals(HistoryStatus.initial));
      expect(bloc.state.scans, isEmpty);
      expect(bloc.state.hasReachedMax, isFalse);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.currentPage, equals(0));
    });

    group('LoadHistoryEvent', () {
      blocTest<HistoryBloc, HistoryState>(
        'emits [loading, loaded] when history is loaded successfully',
        build: () {
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => Right(tScans));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadHistoryEvent()),
        expect: () => [
          const HistoryState(status: HistoryStatus.loading),
          HistoryState(
            status: HistoryStatus.loaded,
            scans: tScans,
            hasReachedMax: true, // 3 scans < 50 limit
            currentPage: 0,
          ),
        ],
        verify: (_) {
          verify(() => mockGetScanHistory()).called(1);
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [loading, loaded] with hasReachedMax=false when scans equal limit',
        build: () {
          final manyScans = List.generate(
            50,
            (i) => ScanHistory(
              id: i,
              barcode: i.toString().padLeft(12, '0'),
              productName: 'Product $i',
              ingredients: ['Ingredient $i'],
              detectedCarcinogenIds: const [],
              overallRiskLevel: RiskLevel.safe,
              scannedAt: DateTime.now(),
            ),
          );
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => Right(manyScans));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadHistoryEvent()),
        expect: () => [
          const HistoryState(status: HistoryStatus.loading),
          isA<HistoryState>()
              .having((s) => s.status, 'status', HistoryStatus.loaded)
              .having((s) => s.scans.length, 'scans length', 50)
              .having((s) => s.hasReachedMax, 'hasReachedMax', false),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [loading, error] when loading history fails',
        build: () {
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => const Left(CacheFailure('Database error')));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadHistoryEvent()),
        expect: () => [
          const HistoryState(status: HistoryStatus.loading),
          const HistoryState(
            status: HistoryStatus.error,
            errorMessage: 'Database error',
          ),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [loading, loaded] with empty list when no history exists',
        build: () {
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => const Right([]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadHistoryEvent()),
        expect: () => [
          const HistoryState(status: HistoryStatus.loading),
          const HistoryState(
            status: HistoryStatus.loaded,
            scans: [],
            hasReachedMax: true,
            currentPage: 0,
          ),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'uses custom limit parameter',
        build: () {
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => Right([tScanHistory1]));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadHistoryEvent(limit: 10)),
        expect: () => [
          const HistoryState(status: HistoryStatus.loading),
          HistoryState(
            status: HistoryStatus.loaded,
            scans: [tScanHistory1],
            hasReachedMax: true, // 1 < 10
            currentPage: 0,
          ),
        ],
      );
    });

    group('LoadMoreHistoryEvent', () {
      blocTest<HistoryBloc, HistoryState>(
        'does nothing when hasReachedMax is true',
        build: () => bloc,
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: tScans,
          hasReachedMax: true,
        ),
        act: (bloc) => bloc.add(const LoadMoreHistoryEvent()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetScanHistory());
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [loadingMore, loaded] when loading more succeeds',
        build: () {
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => Right(tScans));
          return bloc;
        },
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: [tScanHistory1],
          hasReachedMax: false,
          currentPage: 0,
        ),
        act: (bloc) => bloc.add(const LoadMoreHistoryEvent()),
        expect: () => [
          HistoryState(
            status: HistoryStatus.loadingMore,
            scans: [tScanHistory1],
            hasReachedMax: false,
            currentPage: 0,
          ),
          HistoryState(
            status: HistoryStatus.loaded,
            scans: tScans,
            hasReachedMax: true,
          ),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits [loadingMore, loaded with error] when loading more fails',
        build: () {
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => const Left(CacheFailure('Read error')));
          return bloc;
        },
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: [tScanHistory1],
          hasReachedMax: false,
        ),
        act: (bloc) => bloc.add(const LoadMoreHistoryEvent()),
        expect: () => [
          HistoryState(
            status: HistoryStatus.loadingMore,
            scans: [tScanHistory1],
            hasReachedMax: false,
          ),
          HistoryState(
            status: HistoryStatus.loaded,
            scans: [tScanHistory1],
            hasReachedMax: false,
            errorMessage: 'Read error',
          ),
        ],
      );
    });

    group('DeleteScanEvent', () {
      blocTest<HistoryBloc, HistoryState>(
        'removes scan from state when deletion succeeds',
        build: () {
          when(() => mockDeleteScan(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: tScans,
        ),
        act: (bloc) => bloc.add(const DeleteScanEvent(scanId: 2)),
        expect: () => [
          HistoryState(
            status: HistoryStatus.loaded,
            scans: [tScanHistory1, tScanHistory3], // tScanHistory2 removed
          ),
        ],
        verify: (_) {
          verify(() => mockDeleteScan(2)).called(1);
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'emits error message when deletion fails',
        build: () {
          when(() => mockDeleteScan(any()))
              .thenAnswer((_) async => const Left(CacheFailure('Delete failed')));
          return bloc;
        },
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: tScans,
        ),
        act: (bloc) => bloc.add(const DeleteScanEvent(scanId: 1)),
        expect: () => [
          HistoryState(
            status: HistoryStatus.loaded,
            scans: tScans, // Unchanged
            errorMessage: 'Delete failed',
          ),
        ],
      );

      blocTest<HistoryBloc, HistoryState>(
        'handles deletion of non-existent scan gracefully',
        build: () {
          when(() => mockDeleteScan(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: tScans,
        ),
        act: (bloc) => bloc.add(const DeleteScanEvent(scanId: 999)),
        // No state emission expected because the list doesn't change
        // (Equatable prevents duplicate state emissions)
        expect: () => [],
        verify: (_) {
          verify(() => mockDeleteScan(999)).called(1);
        },
      );

      blocTest<HistoryBloc, HistoryState>(
        'handles deletion of last scan',
        build: () {
          when(() => mockDeleteScan(any()))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: [tScanHistory1],
        ),
        act: (bloc) => bloc.add(const DeleteScanEvent(scanId: 1)),
        expect: () => [
          const HistoryState(
            status: HistoryStatus.loaded,
            scans: [],
          ),
        ],
      );
    });

    group('RefreshHistoryEvent', () {
      blocTest<HistoryBloc, HistoryState>(
        'triggers LoadHistoryEvent',
        build: () {
          when(() => mockGetScanHistory())
              .thenAnswer((_) async => Right(tScans));
          return bloc;
        },
        seed: () => HistoryState(
          status: HistoryStatus.loaded,
          scans: [tScanHistory1],
        ),
        act: (bloc) => bloc.add(const RefreshHistoryEvent()),
        expect: () => [
          HistoryState(
            status: HistoryStatus.loading,
            scans: [tScanHistory1],
          ),
          HistoryState(
            status: HistoryStatus.loaded,
            scans: tScans,
            hasReachedMax: true,
            currentPage: 0,
          ),
        ],
      );
    });
  });

  group('HistoryState', () {
    test('isEmpty returns true when scans are empty and loaded', () {
      const state = HistoryState(
        status: HistoryStatus.loaded,
        scans: [],
      );
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty returns false when scans exist', () {
      final state = HistoryState(
        status: HistoryStatus.loaded,
        scans: [tScanHistory1],
      );
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty returns false when status is not loaded', () {
      const state = HistoryState(
        status: HistoryStatus.initial,
        scans: [],
      );
      expect(state.isEmpty, isFalse);
    });

    test('totalScans returns correct count', () {
      final state = HistoryState(
        status: HistoryStatus.loaded,
        scans: tScans,
      );
      expect(state.totalScans, equals(3));
    });

    test('copyWith creates new instance with updated values', () {
      const original = HistoryState(
        status: HistoryStatus.initial,
        scans: [],
        hasReachedMax: false,
        currentPage: 0,
      );

      final updated = original.copyWith(
        status: HistoryStatus.loaded,
        hasReachedMax: true,
        currentPage: 1,
      );

      expect(updated.status, equals(HistoryStatus.loaded));
      expect(updated.scans, isEmpty);
      expect(updated.hasReachedMax, isTrue);
      expect(updated.currentPage, equals(1));
    });

    test('props returns correct values', () {
      final state = HistoryState(
        status: HistoryStatus.loaded,
        scans: tScans,
        hasReachedMax: true,
        errorMessage: 'Error',
        currentPage: 5,
      );

      expect(state.props, contains(HistoryStatus.loaded));
      expect(state.props, contains(tScans));
      expect(state.props, contains(true));
      expect(state.props, contains('Error'));
      expect(state.props, contains(5));
    });
  });

  group('HistoryEvent', () {
    test('LoadHistoryEvent supports value equality', () {
      const event1 = LoadHistoryEvent(limit: 50, offset: 0);
      const event2 = LoadHistoryEvent(limit: 50, offset: 0);
      const event3 = LoadHistoryEvent(limit: 25, offset: 10);

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('DeleteScanEvent supports value equality', () {
      const event1 = DeleteScanEvent(scanId: 1);
      const event2 = DeleteScanEvent(scanId: 1);
      const event3 = DeleteScanEvent(scanId: 2);

      expect(event1, equals(event2));
      expect(event1, isNot(equals(event3)));
    });

    test('LoadMoreHistoryEvent supports value equality', () {
      const event1 = LoadMoreHistoryEvent();
      const event2 = LoadMoreHistoryEvent();

      expect(event1, equals(event2));
    });

    test('RefreshHistoryEvent supports value equality', () {
      const event1 = RefreshHistoryEvent();
      const event2 = RefreshHistoryEvent();

      expect(event1, equals(event2));
    });

    test('ClearHistoryEvent supports value equality', () {
      const event1 = ClearHistoryEvent();
      const event2 = ClearHistoryEvent();

      expect(event1, equals(event2));
    });
  });
}