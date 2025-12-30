import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safeeats/features/scanner/presentation/bloc/scanner_bloc.dart';
import 'package:safeeats/features/scanner/presentation/bloc/scanner_event.dart';
import 'package:safeeats/features/scanner/presentation/bloc/scanner_state.dart';

void main() {
  late ScannerBloc scannerBloc;

  setUp(() {
    scannerBloc = ScannerBloc();
  });

  tearDown(() {
    scannerBloc.close();
  });

  group('ScannerBloc', () {
    test('initial state is ScannerState with initial status', () {
      expect(scannerBloc.state, const ScannerState());
      expect(scannerBloc.state.status, ScannerStatus.initial);
      expect(scannerBloc.state.detectedBarcode, isNull);
      expect(scannerBloc.state.isFlashOn, isFalse);
      expect(scannerBloc.state.isFrontCamera, isFalse);
    });

    group('StartScanningEvent', () {
      blocTest<ScannerBloc, ScannerState>(
        'emits scanning state when StartScanningEvent is added',
        build: () => scannerBloc,
        act: (bloc) => bloc.add(const StartScanningEvent()),
        expect: () => [
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.scanning)
              .having((s) => s.detectedBarcode, 'detectedBarcode', isNull)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'clears previous barcode when starting new scan',
        build: () => scannerBloc,
        seed: () => const ScannerState(
          status: ScannerStatus.barcodeDetected,
          detectedBarcode: '1234567890128',
          barcodeFormat: 'EAN-13',
        ),
        act: (bloc) => bloc.add(const StartScanningEvent()),
        expect: () => [
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.scanning)
              .having((s) => s.detectedBarcode, 'detectedBarcode', isNull)
              .having((s) => s.barcodeFormat, 'barcodeFormat', isNull),
        ],
      );
    });

    group('StopScanningEvent', () {
      blocTest<ScannerBloc, ScannerState>(
        'emits paused state when StopScanningEvent is added',
        build: () => scannerBloc,
        seed: () => const ScannerState(status: ScannerStatus.scanning),
        act: (bloc) => bloc.add(const StopScanningEvent()),
        expect: () => [
          isA<ScannerState>().having(
            (s) => s.status,
            'status',
            ScannerStatus.paused,
          ),
        ],
      );
    });

    group('BarcodeDetectedEvent', () {
      const testBarcode = '1234567890128';
      const testFormat = 'EAN-13';

      blocTest<ScannerBloc, ScannerState>(
        'emits barcodeDetected state with barcode data',
        build: () => scannerBloc,
        seed: () => const ScannerState(status: ScannerStatus.scanning),
        act: (bloc) => bloc.add(const BarcodeDetectedEvent(
          barcode: testBarcode,
          format: testFormat,
        )),
        expect: () => [
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.barcodeDetected)
              .having((s) => s.detectedBarcode, 'detectedBarcode', testBarcode)
              .having((s) => s.barcodeFormat, 'barcodeFormat', testFormat),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'handles barcode without format',
        build: () => scannerBloc,
        seed: () => const ScannerState(status: ScannerStatus.scanning),
        act: (bloc) => bloc.add(const BarcodeDetectedEvent(
          barcode: testBarcode,
        )),
        expect: () => [
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.barcodeDetected)
              .having((s) => s.detectedBarcode, 'detectedBarcode', testBarcode)
              .having((s) => s.barcodeFormat, 'barcodeFormat', isNull),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'prevents duplicate detection of same barcode',
        build: () => scannerBloc,
        seed: () => const ScannerState(
          status: ScannerStatus.barcodeDetected,
          detectedBarcode: testBarcode,
        ),
        act: (bloc) => bloc.add(const BarcodeDetectedEvent(
          barcode: testBarcode,
        )),
        expect: () => [], // No new state should be emitted
      );

      blocTest<ScannerBloc, ScannerState>(
        'allows detection of different barcode',
        build: () => scannerBloc,
        seed: () => const ScannerState(
          status: ScannerStatus.barcodeDetected,
          detectedBarcode: testBarcode,
        ),
        act: (bloc) => bloc.add(const BarcodeDetectedEvent(
          barcode: '9876543210982',
        )),
        expect: () => [
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.barcodeDetected)
              .having((s) => s.detectedBarcode, 'detectedBarcode', '9876543210982'),
        ],
      );
    });

    group('ResetScannerEvent', () {
      blocTest<ScannerBloc, ScannerState>(
        'resets to scanning state with default values',
        build: () => scannerBloc,
        seed: () => const ScannerState(
          status: ScannerStatus.barcodeDetected,
          detectedBarcode: '1234567890128',
          barcodeFormat: 'EAN-13',
          isFlashOn: true,
          isFrontCamera: true,
        ),
        act: (bloc) => bloc.add(const ResetScannerEvent()),
        expect: () => [
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.scanning)
              .having((s) => s.detectedBarcode, 'detectedBarcode', isNull)
              .having((s) => s.barcodeFormat, 'barcodeFormat', isNull)
              // Note: Flash and camera settings are preserved by the const constructor
              .having((s) => s.isFlashOn, 'isFlashOn', isFalse)
              .having((s) => s.isFrontCamera, 'isFrontCamera', isFalse),
        ],
      );
    });

    group('ToggleFlashEvent', () {
      blocTest<ScannerBloc, ScannerState>(
        'toggles flash on when off',
        build: () => scannerBloc,
        seed: () => const ScannerState(isFlashOn: false),
        act: (bloc) => bloc.add(const ToggleFlashEvent()),
        expect: () => [
          isA<ScannerState>().having((s) => s.isFlashOn, 'isFlashOn', isTrue),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'toggles flash off when on',
        build: () => scannerBloc,
        seed: () => const ScannerState(isFlashOn: true),
        act: (bloc) => bloc.add(const ToggleFlashEvent()),
        expect: () => [
          isA<ScannerState>().having((s) => s.isFlashOn, 'isFlashOn', isFalse),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'toggles flash multiple times correctly',
        build: () => scannerBloc,
        act: (bloc) {
          bloc.add(const ToggleFlashEvent());
          bloc.add(const ToggleFlashEvent());
          bloc.add(const ToggleFlashEvent());
        },
        expect: () => [
          isA<ScannerState>().having((s) => s.isFlashOn, 'isFlashOn', isTrue),
          isA<ScannerState>().having((s) => s.isFlashOn, 'isFlashOn', isFalse),
          isA<ScannerState>().having((s) => s.isFlashOn, 'isFlashOn', isTrue),
        ],
      );
    });

    group('SwitchCameraEvent', () {
      blocTest<ScannerBloc, ScannerState>(
        'switches to front camera when using back camera',
        build: () => scannerBloc,
        seed: () => const ScannerState(isFrontCamera: false),
        act: (bloc) => bloc.add(const SwitchCameraEvent()),
        expect: () => [
          isA<ScannerState>().having(
            (s) => s.isFrontCamera,
            'isFrontCamera',
            isTrue,
          ),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'switches to back camera when using front camera',
        build: () => scannerBloc,
        seed: () => const ScannerState(isFrontCamera: true),
        act: (bloc) => bloc.add(const SwitchCameraEvent()),
        expect: () => [
          isA<ScannerState>().having(
            (s) => s.isFrontCamera,
            'isFrontCamera',
            isFalse,
          ),
        ],
      );
    });

    group('State combinations', () {
      blocTest<ScannerBloc, ScannerState>(
        'maintains flash state during scanning operations',
        build: () => scannerBloc,
        seed: () => const ScannerState(isFlashOn: true),
        act: (bloc) {
          bloc.add(const StartScanningEvent());
          bloc.add(const BarcodeDetectedEvent(barcode: '123'));
        },
        expect: () => [
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.scanning)
              .having((s) => s.isFlashOn, 'isFlashOn', isTrue),
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.barcodeDetected)
              .having((s) => s.isFlashOn, 'isFlashOn', isTrue),
        ],
      );

      blocTest<ScannerBloc, ScannerState>(
        'handles complete scanning workflow',
        build: () => scannerBloc,
        act: (bloc) async {
          // Start scanning
          bloc.add(const StartScanningEvent());
          await Future.delayed(const Duration(milliseconds: 10));
          
          // Toggle flash
          bloc.add(const ToggleFlashEvent());
          await Future.delayed(const Duration(milliseconds: 10));
          
          // Detect barcode
          bloc.add(const BarcodeDetectedEvent(
            barcode: '1234567890128',
            format: 'EAN-13',
          ));
          await Future.delayed(const Duration(milliseconds: 10));
          
          // Reset for next scan
          bloc.add(const ResetScannerEvent());
        },
        expect: () => [
          // Start scanning
          isA<ScannerState>().having((s) => s.status, 'status', ScannerStatus.scanning),
          // Flash toggled on
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.scanning)
              .having((s) => s.isFlashOn, 'isFlashOn', isTrue),
          // Barcode detected
          isA<ScannerState>()
              .having((s) => s.status, 'status', ScannerStatus.barcodeDetected)
              .having((s) => s.detectedBarcode, 'barcode', '1234567890128'),
          // Reset
          isA<ScannerState>().having((s) => s.status, 'status', ScannerStatus.scanning),
        ],
      );
    });
  });

  group('ScannerState', () {
    test('copyWith creates correct copy', () {
      const original = ScannerState(
        status: ScannerStatus.initial,
        isFlashOn: false,
        isFrontCamera: false,
      );

      final copied = original.copyWith(
        status: ScannerStatus.scanning,
        detectedBarcode: '123',
        isFlashOn: true,
      );

      expect(copied.status, ScannerStatus.scanning);
      expect(copied.detectedBarcode, '123');
      expect(copied.isFlashOn, isTrue);
      expect(copied.isFrontCamera, isFalse); // Unchanged
      expect(original.status, ScannerStatus.initial); // Original unchanged
    });

    test('props returns correct list', () {
      const state = ScannerState(
        status: ScannerStatus.barcodeDetected,
        detectedBarcode: '123',
        barcodeFormat: 'EAN-13',
        isFlashOn: true,
        isFrontCamera: false,
        errorMessage: null,
      );

      expect(state.props, [
        ScannerStatus.barcodeDetected,
        '123',
        'EAN-13',
        true,
        false,
        null,
      ]);
    });

    test('two states with same properties are equal', () {
      const state1 = ScannerState(
        status: ScannerStatus.scanning,
        isFlashOn: true,
      );
      const state2 = ScannerState(
        status: ScannerStatus.scanning,
        isFlashOn: true,
      );

      expect(state1, equals(state2));
    });
  });
}