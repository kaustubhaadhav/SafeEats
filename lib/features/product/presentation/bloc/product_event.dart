import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class FetchProductEvent extends ProductEvent {
  final String barcode;

  const FetchProductEvent({required this.barcode});

  @override
  List<Object> get props => [barcode];
}

class ClearProductEvent extends ProductEvent {
  const ClearProductEvent();
}

class RefreshProductEvent extends ProductEvent {
  final String barcode;

  const RefreshProductEvent({required this.barcode});

  @override
  List<Object> get props => [barcode];
}