import 'package:equatable/equatable.dart';
import 'ingredient.dart';

class Product extends Equatable {
  final String barcode;
  final String name;
  final String? brand;
  final String? imageUrl;
  final List<Ingredient> ingredients;
  final String? ingredientsText;
  final Map<String, dynamic>? nutriments;
  final String? quantity;
  final String? categories;

  const Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.ingredients,
    this.ingredientsText,
    this.nutriments,
    this.quantity,
    this.categories,
  });

  /// Returns all ingredient names as a list of strings
  List<String> get ingredientNames {
    if (ingredients.isNotEmpty) {
      return ingredients.map((i) => i.name).toList();
    }
    if (ingredientsText != null && ingredientsText!.isNotEmpty) {
      return ingredientsText!
          .split(RegExp(r'[,;]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Returns true if the product has ingredient information
  bool get hasIngredients {
    return ingredients.isNotEmpty || 
           (ingredientsText != null && ingredientsText!.isNotEmpty);
  }

  @override
  List<Object?> get props => [barcode, name, brand, ingredients];
}