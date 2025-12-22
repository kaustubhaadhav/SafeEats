import 'package:flutter_bloc/flutter_bloc.dart';
import 'scanner_event.dart';
import 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc() : super(const ScannerState()) {
    on<StartScanningEvent>(_onStartScanning);
    on<StopScanningEvent>(_onStopScanning);
    on<BarcodeDetectedEvent>(_onBarcodeDetected);
    on<ResetScannerEvent>(_onResetScanner);
    on<ToggleFlashEvent>(_onToggleFlash);
    on<SwitchCameraEvent>(_onSwitchCamera);
  }

  void _onStartScanning(
    StartScanningEvent event,
    Emitter<ScannerState> emit,
  ) {
    emit(state.copyWith(
      status: ScannerStatus.scanning,
      detectedBarcode: null,
      barcodeFormat: null,
      errorMessage: null,
    ));
  }

  void _onStopScanning(
    StopScanningEvent event,
    Emitter<ScannerState> emit,
  ) {
    emit(state.copyWith(status: ScannerStatus.paused));
  }

  void _onBarcodeDetected(
    BarcodeDetectedEvent event,
    Emitter<ScannerState> emit,
  ) {
    // Prevent duplicate detections
    if (state.status == ScannerStatus.barcodeDetected &&
        state.detectedBarcode == event.barcode) {
      return;
    }

    emit(state.copyWith(
      status: ScannerStatus.barcodeDetected,
      detectedBarcode: event.barcode,
      barcodeFormat: event.format,
    ));
  }

  void _onResetScanner(
    ResetScannerEvent event,
    Emitter<ScannerState> emit,
  ) {
    emit(const ScannerState(status: ScannerStatus.scanning));
  }

  void _onToggleFlash(
    ToggleFlashEvent event,
    Emitter<ScannerState> emit,
  ) {
    emit(state.copyWith(isFlashOn: !state.isFlashOn));
  }

  void _onSwitchCamera(
    SwitchCameraEvent event,
    Emitter<ScannerState> emit,
  ) {
    emit(state.copyWith(isFrontCamera: !state.isFrontCamera));
  }
}