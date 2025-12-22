import 'package:equatable/equatable.dart';

class Ingredient extends Equatable {
  final String id;
  final String name;
  final double? percent;
  final bool? isVegan;
  final bool? isVegetarian;
  final bool? isPalmOilFree;

  const Ingredient({
    required this.id,
    required this.name,
    this.percent,
    this.isVegan,
    this.isVegetarian,
    this.isPalmOilFree,
  });

  @override
  List<Object?> get props => [id, name, percent];
}