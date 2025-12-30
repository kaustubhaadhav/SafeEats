/// Utility class for validating barcode formats
class BarcodeValidator {
  /// Validates a barcode and returns a validation result
  static BarcodeValidationResult validate(String? barcode) {
    if (barcode == null || barcode.isEmpty) {
      return BarcodeValidationResult(
        isValid: false,
        error: 'Barcode cannot be empty',
      );
    }

    // Remove any whitespace
    final cleanBarcode = barcode.trim().replaceAll(' ', '');

    // Check if barcode contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleanBarcode)) {
      return BarcodeValidationResult(
        isValid: false,
        error: 'Barcode must contain only numbers',
      );
    }

    // Check minimum length (shortest valid barcode is UPC-E with 8 digits)
    if (cleanBarcode.length < 8) {
      return BarcodeValidationResult(
        isValid: false,
        error: 'Barcode is too short. Must be at least 8 digits.',
      );
    }

    // Check maximum length (ISBN-13 and EAN-13 are 13 digits)
    if (cleanBarcode.length > 14) {
      return BarcodeValidationResult(
        isValid: false,
        error: 'Barcode is too long. Maximum 14 digits allowed.',
      );
    }

    // Validate check digit for common formats
    final checkDigitValid = _validateCheckDigit(cleanBarcode);
    if (!checkDigitValid) {
      return BarcodeValidationResult(
        isValid: false,
        error: 'Invalid barcode check digit. Please verify the barcode.',
      );
    }

    return BarcodeValidationResult(
      isValid: true,
      cleanedBarcode: cleanBarcode,
    );
  }

  /// Validates the check digit using the standard algorithm for EAN/UPC barcodes
  static bool _validateCheckDigit(String barcode) {
    // For 8, 12, 13, or 14 digit barcodes, use the standard EAN/UPC check digit algorithm
    if (![8, 12, 13, 14].contains(barcode.length)) {
      // For non-standard lengths, we can't validate the check digit
      return true;
    }

    final digits = barcode.split('').map(int.parse).toList();
    final checkDigit = digits.last;

    int sum = 0;
    for (int i = 0; i < digits.length - 1; i++) {
      // Standard EAN/UPC algorithm:
      // - EAN-13 (odd length): positions 1,3,5... multiply by 1; positions 2,4,6... multiply by 3
      // - UPC-A (even length): positions 1,3,5... multiply by 3; positions 2,4,6... multiply by 1
      // Formula: for odd-length barcodes, even indices get multiplier 3; for even-length, odd indices get multiplier 3
      final multiplier = (barcode.length + i) % 2 == 1 ? 1 : 3;
      sum += digits[i] * multiplier;
    }

    final calculatedCheckDigit = (10 - (sum % 10)) % 10;
    return calculatedCheckDigit == checkDigit;
  }
}

/// Result of barcode validation
class BarcodeValidationResult {
  final bool isValid;
  final String? error;
  final String? cleanedBarcode;

  BarcodeValidationResult({
    required this.isValid,
    this.error,
    this.cleanedBarcode,
  });
}