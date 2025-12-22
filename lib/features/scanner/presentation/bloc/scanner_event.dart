import 'package:equatable/equatable.dart';

abstract class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

class StartScanningEvent extends ScannerEvent {
  const StartScanningEvent();
}

class StopScanningEvent extends ScannerEvent {
  const StopScanningEvent();
}

class BarcodeDetectedEvent extends ScannerEvent {
  final String barcode;
  final String? format;

  const BarcodeDetectedEvent({
    required this.barcode,
    this.format,
  });

  @override
  List<Object?> get props => [barcode, format];
}

class ResetScannerEvent extends ScannerEvent {
  const ResetScannerEvent();
}

class ToggleFlashEvent extends ScannerEvent {
  const ToggleFlashEvent();
}

class SwitchCameraEvent extends ScannerEvent {
  const SwitchCameraEvent();
}