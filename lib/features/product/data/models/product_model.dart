import 'dart:convert';
import '../../domain/entities/product.dart';
import '../../domain/entities/ingredient.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.barcode,
    required super.name,
    super.brand,
    super.imageUrl,
    required super.ingredients,
    super.ingredientsText,
    super.nutriments,
    super.quantity,
    super.categories,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<IngredientModel> ingredients = [];

    if (json['ingredients'] != null && json['ingredients'] is List) {
      ingredients = (json['ingredients'] as List)
          .map((i) => IngredientModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    return ProductModel(
      barcode: json['code']?.toString() ?? json['barcode']?.toString() ?? '',
      name: json['product_name']?.toString() ?? 
            json['product_name_en']?.toString() ?? 
            'Unknown Product',
      brand: json['brands']?.toString(),
      imageUrl: json['image_url']?.toString() ?? 
                json['image_front_url']?.toString() ??
                json['image_front_small_url']?.toString(),
      ingredients: ingredients,
      ingredientsText: json['ingredients_text']?.toString() ??
                       json['ingredients_text_en']?.toString(),
      nutriments: json['nutriments'] as Map<String, dynamic>?,
      quantity: json['quantity']?.toString(),
      categories: json['categories']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': barcode,
      'product_name': name,
      'brands': brand,
      'image_url': imageUrl,
      'ingredients': ingredients
          .map((i) => (i as IngredientModel).toJson())
          .toList(),
      'ingredients_text': ingredientsText,
      'nutriments': nutriments,
      'quantity': quantity,
      'categories': categories,
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory ProductModel.fromJsonString(String jsonString) {
    return ProductModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  factory ProductModel.fromEntity(Product product) {
    return ProductModel(
      barcode: product.barcode,
      name: product.name,
      brand: product.brand,
      imageUrl: product.imageUrl,
      ingredients: product.ingredients,
      ingredientsText: product.ingredientsText,
      nutriments: product.nutriments,
      quantity: product.quantity,
      categories: product.categories,
    );
  }
}

class IngredientModel extends Ingredient {
  const IngredientModel({
    required super.id,
    required super.name,
    super.percent,
    super.isVegan,
    super.isVegetarian,
    super.isPalmOilFree,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id']?.toString() ?? '',
      name: json['text']?.toString() ?? json['id']?.toString() ?? '',
      percent: _parseDouble(json['percent_estimate'] ?? json['percent']),
      isVegan: json['vegan'] != 'no',
      isVegetarian: json['vegetarian'] != 'no',
      isPalmOilFree: json['from_palm_oil'] != 'yes',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': name,
      'percent_estimate': percent,
      'vegan': isVegan == true ? 'yes' : (isVegan == false ? 'no' : 'maybe'),
      'vegetarian': isVegetarian == true ? 'yes' : (isVegetarian == false ? 'no' : 'maybe'),
      'from_palm_oil': isPalmOilFree == true ? 'no' : (isPalmOilFree == false ? 'yes' : 'maybe'),
    };
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}