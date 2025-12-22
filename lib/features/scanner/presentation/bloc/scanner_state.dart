import 'package:equatable/equatable.dart';

enum ScannerStatus {
  initial,
  scanning,
  paused,
  barcodeDetected,
  error,
}

class ScannerState extends Equatable {
  final ScannerStatus status;
  final String? detectedBarcode;
  final String? barcodeFormat;
  final bool isFlashOn;
  final bool isFrontCamera;
  final String? errorMessage;

  const ScannerState({
    this.status = ScannerStatus.initial,
    this.detectedBarcode,
    this.barcodeFormat,
    this.isFlashOn = false,
    this.isFrontCamera = false,
    this.errorMessage,
  });

  ScannerState copyWith({
    ScannerStatus? status,
    String? detectedBarcode,
    String? barcodeFormat,
    bool? isFlashOn,
    bool? isFrontCamera,
    String? errorMessage,
  }) {
    return ScannerState(
      status: status ?? this.status,
      detectedBarcode: detectedBarcode ?? this.detectedBarcode,
      barcodeFormat: barcodeFormat ?? this.barcodeFormat,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        detectedBarcode,
        barcodeFormat,
        isFlashOn,
        isFrontCamera,
        errorMessage,
      ];
}