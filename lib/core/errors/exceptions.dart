class ServerException implements Exception {
  final String message;
  
  const ServerException([this.message = 'Server error occurred']);
  
  @override
  String toString() => message;
}

class CacheException implements Exception {
  final String message;
  
  const CacheException([this.message = 'Cache error occurred']);
  
  @override
  String toString() => message;
}

class NotFoundException implements Exception {
  final String message;
  
  const NotFoundException([this.message = 'Resource not found']);
  
  @override
  String toString() => message;
}

class InvalidBarcodeException implements Exception {
  final String message;
  
  const InvalidBarcodeException([this.message = 'Invalid barcode format']);
  
  @override
  String toString() => message;
}