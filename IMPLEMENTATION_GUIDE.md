# Yuko Implementation Guide

This document contains all the implementation details, code samples, and data needed to build the Yuko food carcinogen scanner app.

## Table of Contents

1. [Carcinogen Database](#carcinogen-database)
2. [Code Implementation](#code-implementation)
3. [API Integration](#api-integration)
4. [UI Components](#ui-components)

---

## Carcinogen Database

### IARC Carcinogens Data (iarc_carcinogens.json)

```json
{
  "source": "International Agency for Research on Cancer (IARC)",
  "last_updated": "2024-01-01",
  "classifications": {
    "group1": "Carcinogenic to humans",
    "group2a": "Probably carcinogenic to humans",
    "group2b": "Possibly carcinogenic to humans",
    "group3": "Not classifiable as to its carcinogenicity to humans"
  },
  "carcinogens": [
    {
      "id": "iarc_001",
      "name": "Acrylamide",
      "aliases": ["acrylic amide", "2-propenamide", "ethylene carboxamide"],
      "cas_number": "79-06-1",
      "group": "group2a",
      "risk_level": 3,
      "description": "Formed when starchy foods are cooked at high temperatures (frying, baking, roasting). Found in french fries, potato chips, bread, and coffee.",
      "common_foods": ["french fries", "potato chips", "bread", "coffee", "crackers", "breakfast cereals"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_002",
      "name": "Aflatoxins",
      "aliases": ["aflatoxin b1", "aflatoxin b2", "aflatoxin g1", "aflatoxin g2"],
      "cas_number": "1402-68-2",
      "group": "group1",
      "risk_level": 4,
      "description": "Naturally occurring mycotoxins produced by Aspergillus fungi. Can contaminate crops like peanuts, corn, and tree nuts.",
      "common_foods": ["peanuts", "corn", "tree nuts", "cottonseed", "spices"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_003",
      "name": "Alcohol (Ethanol)",
      "aliases": ["ethyl alcohol", "ethanol", "alcohol"],
      "cas_number": "64-17-5",
      "group": "group1",
      "risk_level": 4,
      "description": "Consumption of alcoholic beverages is carcinogenic. Associated with cancers of the mouth, pharynx, larynx, esophagus, liver, colorectum, and breast.",
      "common_foods": ["beer", "wine", "spirits", "liquor", "alcoholic beverages"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_004",
      "name": "Arsenic",
      "aliases": ["arsenite", "arsenate", "inorganic arsenic"],
      "cas_number": "7440-38-2",
      "group": "group1",
      "risk_level": 4,
      "description": "Can be found in rice, drinking water, and some seafood. Chronic exposure linked to skin, lung, and bladder cancer.",
      "common_foods": ["rice", "rice products", "some seafood", "apple juice"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_005",
      "name": "Benzene",
      "aliases": ["benzol", "phenyl hydride"],
      "cas_number": "71-43-2",
      "group": "group1",
      "risk_level": 4,
      "description": "Can form in soft drinks containing benzoic acid and ascorbic acid. Causes leukemia.",
      "common_foods": ["some soft drinks", "preserved foods with benzoates"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_006",
      "name": "Benzo[a]pyrene",
      "aliases": ["bap", "3,4-benzopyrene"],
      "cas_number": "50-32-8",
      "group": "group1",
      "risk_level": 4,
      "description": "Polycyclic aromatic hydrocarbon formed during grilling, smoking, and charring of meat.",
      "common_foods": ["grilled meat", "smoked fish", "charred foods", "barbecued foods"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_007",
      "name": "Cadmium",
      "aliases": ["cadmium compounds"],
      "cas_number": "7440-43-9",
      "group": "group1",
      "risk_level": 4,
      "description": "Heavy metal found in certain foods, especially shellfish, organ meats, and some vegetables grown in contaminated soil.",
      "common_foods": ["shellfish", "organ meats", "leafy vegetables", "potatoes"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_008",
      "name": "Formaldehyde",
      "aliases": ["formalin", "methyl aldehyde", "methanal"],
      "cas_number": "50-00-0",
      "group": "group1",
      "risk_level": 4,
      "description": "Can be found naturally in some foods and may be illegally added as a preservative in some regions.",
      "common_foods": ["some preserved foods", "dried foods"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_009",
      "name": "Heterocyclic Amines (HCAs)",
      "aliases": ["hca", "heterocyclic aromatic amines", "haas"],
      "cas_number": null,
      "group": "group2a",
      "risk_level": 3,
      "description": "Formed when muscle meat is cooked at high temperatures. Includes PhIP, MeIQx, and others.",
      "common_foods": ["pan-fried meat", "grilled meat", "barbecued meat", "well-done meat"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_010",
      "name": "Lead",
      "aliases": ["lead compounds", "plumbum"],
      "cas_number": "7439-92-1",
      "group": "group2a",
      "risk_level": 3,
      "description": "Heavy metal that can contaminate food through soil, water, or food processing equipment.",
      "common_foods": ["leafy vegetables", "root vegetables", "some candies", "certain spices"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_011",
      "name": "Nitrates and Nitrites",
      "aliases": ["sodium nitrate", "sodium nitrite", "potassium nitrate", "e250", "e251", "e252"],
      "cas_number": "7631-99-4",
      "group": "group2a",
      "risk_level": 3,
      "description": "Used as preservatives in processed meats. Can form nitrosamines which are carcinogenic.",
      "common_foods": ["bacon", "hot dogs", "ham", "sausages", "deli meats", "cured meats"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_012",
      "name": "N-Nitrosamines",
      "aliases": ["nitrosamines", "ndma", "ndea"],
      "cas_number": null,
      "group": "group2a",
      "risk_level": 3,
      "description": "Formed from nitrites during cooking or digestion. Found in cured meats and some beers.",
      "common_foods": ["cured meats", "beer", "smoked fish", "processed cheese"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_013",
      "name": "Ochratoxin A",
      "aliases": ["ota", "ochratoxin"],
      "cas_number": "303-47-9",
      "group": "group2b",
      "risk_level": 2,
      "description": "Mycotoxin produced by certain molds. Found in cereals, dried fruits, wine, and coffee.",
      "common_foods": ["cereals", "dried fruits", "wine", "coffee", "spices", "grape juice"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_014",
      "name": "Polycyclic Aromatic Hydrocarbons (PAHs)",
      "aliases": ["pahs", "polyaromatic hydrocarbons"],
      "cas_number": null,
      "group": "group2a",
      "risk_level": 3,
      "description": "Group of chemicals formed during incomplete combustion. Found in smoked, grilled, and charred foods.",
      "common_foods": ["smoked meats", "grilled foods", "charred foods", "smoked fish"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_015",
      "name": "Processed Meat",
      "aliases": ["processed meats"],
      "cas_number": null,
      "group": "group1",
      "risk_level": 4,
      "description": "Meat that has been transformed through salting, curing, fermentation, smoking, or other processes to enhance flavor or preservation.",
      "common_foods": ["hot dogs", "bacon", "ham", "sausages", "corned beef", "beef jerky", "canned meat"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_016",
      "name": "Red Meat",
      "aliases": ["mammalian meat"],
      "cas_number": null,
      "group": "group2a",
      "risk_level": 3,
      "description": "Unprocessed mammalian muscle meat such as beef, veal, pork, lamb, mutton, horse, and goat.",
      "common_foods": ["beef", "pork", "lamb", "veal", "mutton"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_017",
      "name": "Styrene",
      "aliases": ["ethenylbenzene", "vinylbenzene", "phenylethylene"],
      "cas_number": "100-42-5",
      "group": "group2a",
      "risk_level": 3,
      "description": "Can migrate from polystyrene food containers into food, especially when heated.",
      "common_foods": ["foods in styrofoam containers", "packaged foods"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_018",
      "name": "Titanium Dioxide",
      "aliases": ["e171", "tio2", "titanium white"],
      "cas_number": "13463-67-7",
      "group": "group2b",
      "risk_level": 2,
      "description": "Food additive used as a whitening agent. Banned in EU as food additive since 2022.",
      "common_foods": ["candies", "chewing gum", "white sauces", "icing", "some medications"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_019",
      "name": "Furan",
      "aliases": ["furfuran", "oxole"],
      "cas_number": "110-00-9",
      "group": "group2b",
      "risk_level": 2,
      "description": "Formed during thermal treatment of food. Found in coffee, canned foods, and baby foods.",
      "common_foods": ["coffee", "canned foods", "jarred baby food", "soups", "sauces"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    },
    {
      "id": "iarc_020",
      "name": "3-MCPD",
      "aliases": ["3-monochloropropane-1,2-diol", "3-chloropropane-1,2-diol"],
      "cas_number": "96-24-2",
      "group": "group2b",
      "risk_level": 2,
      "description": "Forms during food processing, especially in refined vegetable oils and soy sauce.",
      "common_foods": ["refined oils", "soy sauce", "hydrolyzed vegetable protein", "bread"],
      "source_url": "https://monographs.iarc.who.int/agents-classified-by-the-iarc/"
    }
  ]
}
```

### California Prop 65 Carcinogens (prop65_carcinogens.json)

```json
{
  "source": "California Office of Environmental Health Hazard Assessment (OEHHA)",
  "last_updated": "2024-01-01",
  "description": "Chemicals known to the State of California to cause cancer",
  "carcinogens": [
    {
      "id": "prop65_001",
      "name": "Acrylamide",
      "cas_number": "79-06-1",
      "date_listed": "1990-01-01",
      "risk_level": 3,
      "nsrl": "0.2 µg/day",
      "description": "No Significant Risk Level is 0.2 micrograms per day"
    },
    {
      "id": "prop65_002",
      "name": "Arsenic",
      "cas_number": "7440-38-2",
      "date_listed": "1987-02-27",
      "risk_level": 4,
      "nsrl": "0.06 µg/day",
      "description": "Inorganic arsenic compounds"
    },
    {
      "id": "prop65_003",
      "name": "Benzene",
      "cas_number": "71-43-2",
      "date_listed": "1987-02-27",
      "risk_level": 4,
      "nsrl": "6.4 µg/day",
      "description": "Known to cause leukemia"
    },
    {
      "id": "prop65_004",
      "name": "Bisphenol A (BPA)",
      "cas_number": "80-05-7",
      "date_listed": "2015-05-11",
      "risk_level": 2,
      "nsrl": null,
      "description": "Reproductive toxicant, can leach from food containers"
    },
    {
      "id": "prop65_005",
      "name": "Cadmium",
      "cas_number": "7440-43-9",
      "date_listed": "1987-10-01",
      "risk_level": 4,
      "nsrl": "0.05 µg/day",
      "description": "Heavy metal carcinogen"
    },
    {
      "id": "prop65_006",
      "name": "Lead",
      "cas_number": "7439-92-1",
      "date_listed": "1987-02-27",
      "risk_level": 4,
      "nsrl": "0.5 µg/day",
      "description": "Lead and lead compounds"
    },
    {
      "id": "prop65_007",
      "name": "Mercury",
      "cas_number": "7439-97-6",
      "date_listed": "1987-07-01",
      "risk_level": 3,
      "nsrl": null,
      "description": "Methylmercury compounds, found in fish"
    },
    {
      "id": "prop65_008",
      "name": "Phthalates (DEHP)",
      "cas_number": "117-81-7",
      "date_listed": "2003-12-19",
      "risk_level": 2,
      "nsrl": "310 µg/day",
      "description": "Di(2-ethylhexyl)phthalate, plasticizer"
    },
    {
      "id": "prop65_009",
      "name": "Potassium Bromate",
      "cas_number": "7758-01-2",
      "date_listed": "1990-06-15",
      "risk_level": 3,
      "nsrl": "0.6 µg/day",
      "description": "Bread additive banned in many countries"
    },
    {
      "id": "prop65_010",
      "name": "Propyl Gallate",
      "cas_number": "121-79-9",
      "date_listed": null,
      "risk_level": 2,
      "nsrl": null,
      "description": "Antioxidant food additive (E310)"
    },
    {
      "id": "prop65_011",
      "name": "Butylated Hydroxyanisole (BHA)",
      "cas_number": "25013-16-5",
      "date_listed": "1990-01-01",
      "risk_level": 2,
      "nsrl": null,
      "description": "Antioxidant preservative (E320)"
    },
    {
      "id": "prop65_012",
      "name": "Azodicarbonamide",
      "cas_number": "123-77-3",
      "date_listed": null,
      "risk_level": 2,
      "nsrl": null,
      "description": "Dough conditioner banned in EU and Australia"
    },
    {
      "id": "prop65_013",
      "name": "Brominated Vegetable Oil (BVO)",
      "cas_number": "8016-94-2",
      "date_listed": null,
      "risk_level": 2,
      "nsrl": null,
      "description": "Emulsifier in some citrus-flavored drinks"
    },
    {
      "id": "prop65_014",
      "name": "Carrageenan (degraded)",
      "cas_number": "9000-07-1",
      "date_listed": null,
      "risk_level": 2,
      "nsrl": null,
      "description": "Thickening agent, degraded form is concerning"
    },
    {
      "id": "prop65_015",
      "name": "Aspartame",
      "cas_number": "22839-47-0",
      "date_listed": null,
      "risk_level": 2,
      "nsrl": null,
      "description": "Artificial sweetener, classified as possibly carcinogenic by IARC in 2023"
    },
    {
      "id": "prop65_016",
      "name": "Caramel Color (4-MEI)",
      "cas_number": "822-36-6",
      "date_listed": "2011-01-07",
      "risk_level": 2,
      "nsrl": "29 µg/day",
      "description": "4-Methylimidazole found in caramel coloring"
    },
    {
      "id": "prop65_017",
      "name": "Glyphosate",
      "cas_number": "1071-83-6",
      "date_listed": "2017-07-07",
      "risk_level": 3,
      "nsrl": "1100 µg/day",
      "description": "Herbicide residue found in some foods"
    },
    {
      "id": "prop65_018",
      "name": "Red Dye No. 3 (Erythrosine)",
      "cas_number": "16423-68-0",
      "date_listed": "1990-01-01",
      "risk_level": 2,
      "nsrl": null,
      "description": "Food coloring (E127)"
    },
    {
      "id": "prop65_019",
      "name": "PFAS (PFOA)",
      "cas_number": "335-67-1",
      "date_listed": "2017-11-10",
      "risk_level": 3,
      "nsrl": "0.1 µg/day",
      "description": "Perfluorooctanoic acid, forever chemical"
    },
    {
      "id": "prop65_020",
      "name": "PFAS (PFOS)",
      "cas_number": "1763-23-1",
      "date_listed": "2017-11-10",
      "risk_level": 3,
      "nsrl": null,
      "description": "Perfluorooctane sulfonic acid, forever chemical"
    }
  ]
}
```

---

## Code Implementation

### Main Entry Point (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const YukoApp());
}
```

### App Configuration (app.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/scanner/presentation/bloc/scanner_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/carcinogen/presentation/bloc/carcinogen_bloc.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'injection_container.dart';
import 'features/home/presentation/pages/home_page.dart';

class YukoApp extends StatelessWidget {
  const YukoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ScannerBloc>()),
        BlocProvider(create: (_) => sl<ProductBloc>()),
        BlocProvider(create: (_) => sl<CarcinogenBloc>()),
        BlocProvider(create: (_) => sl<HistoryBloc>()),
      ],
      child: MaterialApp(
        title: 'Yuko',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

### Dependency Injection (injection_container.dart)

```dart
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => Dio(BaseOptions(
    baseUrl: 'https://world.openfoodfacts.org/api/v2',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  )));

  // Database
  final database = await openDatabase(
    'yuko.db',
    version: 1,
    onCreate: _createDatabase,
  );
  sl.registerSingleton<Database>(database);

  // Data sources
  // ... register data sources

  // Repositories
  // ... register repositories

  // Use cases
  // ... register use cases

  // BLoCs
  // ... register blocs
}

Future<void> _createDatabase(Database db, int version) async {
  await db.execute('''
    CREATE TABLE carcinogens (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      aliases TEXT,
      cas_number TEXT,
      source TEXT NOT NULL,
      classification TEXT,
      risk_level INTEGER,
      description TEXT,
      common_foods TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE scan_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      barcode TEXT NOT NULL,
      product_name TEXT,
      brand TEXT,
      image_url TEXT,
      ingredients TEXT,
      detected_carcinogens TEXT,
      overall_risk_level INTEGER,
      scanned_at TEXT
    )
  ''');

  await db.execute('''
    CREATE TABLE cached_products (
      barcode TEXT PRIMARY KEY,
      product_data TEXT,
      cached_at TEXT
    )
  ''');
}
```

### Product Entity (features/product/domain/entities/product.dart)

```dart
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

  const Product({
    required this.barcode,
    required this.name,
    this.brand,
    this.imageUrl,
    required this.ingredients,
    this.ingredientsText,
    this.nutriments,
  });

  @override
  List<Object?> get props => [barcode, name, brand, ingredients];
}
```

### Ingredient Entity (features/product/domain/entities/ingredient.dart)

```dart
import 'package:equatable/equatable.dart';

class Ingredient extends Equatable {
  final String id;
  final String name;
  final double? percent;
  final bool isVegan;
  final bool isVegetarian;

  const Ingredient({
    required this.id,
    required this.name,
    this.percent,
    this.isVegan = true,
    this.isVegetarian = true,
  });

  @override
  List<Object?> get props => [id, name, percent];
}
```

### Carcinogen Entity (features/carcinogen/domain/entities/carcinogen.dart)

```dart
import 'package:equatable/equatable.dart';

enum CarcinogenSource { iarc, prop65 }

enum RiskLevel {
  low(1, 'Low Risk', 0xFF4CAF50),
  medium(2, 'Medium Risk', 0xFFFFC107),
  high(3, 'High Risk', 0xFFFF9800),
  critical(4, 'Critical Risk', 0xFFF44336);

  final int value;
  final String label;
  final int color;

  const RiskLevel(this.value, this.label, this.color);

  static RiskLevel fromValue(int value) {
    return RiskLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RiskLevel.low,
    );
  }
}

class Carcinogen extends Equatable {
  final String id;
  final String name;
  final List<String> aliases;
  final String? casNumber;
  final CarcinogenSource source;
  final String? classification;
  final RiskLevel riskLevel;
  final String description;
  final List<String> commonFoods;
  final String? sourceUrl;

  const Carcinogen({
    required this.id,
    required this.name,
    required this.aliases,
    this.casNumber,
    required this.source,
    this.classification,
    required this.riskLevel,
    required this.description,
    required this.commonFoods,
    this.sourceUrl,
  });

  @override
  List<Object?> get props => [id, name, source];
}
```

### Ingredient Parser Utility (core/utils/ingredient_parser.dart)

```dart
class IngredientParser {
  /// Parses a raw ingredient text and returns a list of normalized ingredient names
  static List<String> parse(String ingredientsText) {
    if (ingredientsText.isEmpty) return [];

    // Remove common noise patterns
    String cleaned = ingredientsText
        .toLowerCase()
        .replaceAll(RegExp(r'\([^)]*\)'), '') // Remove parenthetical info
        .replaceAll(RegExp(r'\[[^\]]*\]'), '') // Remove bracketed info
        .replaceAll(RegExp(r'\d+\.?\d*%'), '') // Remove percentages
        .replaceAll(RegExp(r'contains less than \d+% of:?'), ',')
        .replaceAll(RegExp(r'and/or'), ',')
        .replaceAll(RegExp(r'\bor\b'), ',')
        .replaceAll(RegExp(r'\band\b'), ',')
        .replaceAll(RegExp(r'[*†‡§]'), '') // Remove reference symbols
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace

    // Split by common delimiters
    List<String> ingredients = cleaned
        .split(RegExp(r'[,;:]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 1)
        .toList();

    return ingredients;
  }

  /// Normalizes an ingredient name for matching
  static String normalize(String ingredient) {
    return ingredient
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
```

### Carcinogen Matcher (core/utils/carcinogen_matcher.dart)

```dart
import '../../features/carcinogen/domain/entities/carcinogen.dart';

class CarcinogenMatcher {
  final List<Carcinogen> _carcinogens;

  CarcinogenMatcher(this._carcinogens);

  /// Finds all carcinogens that match the given ingredients
  Map<String, List<Carcinogen>> findMatches(List<String> ingredients) {
    Map<String, List<Carcinogen>> matches = {};

    for (String ingredient in ingredients) {
      String normalized = _normalize(ingredient);
      List<Carcinogen> matchedCarcinogens = [];

      for (Carcinogen carcinogen in _carcinogens) {
        if (_isMatch(normalized, carcinogen)) {
          matchedCarcinogens.add(carcinogen);
        }
      }

      if (matchedCarcinogens.isNotEmpty) {
        matches[ingredient] = matchedCarcinogens;
      }
    }

    return matches;
  }

  /// Calculates the overall risk level based on detected carcinogens
  RiskLevel calculateOverallRisk(List<Carcinogen> carcinogens) {
    if (carcinogens.isEmpty) return RiskLevel.low;

    int maxRisk = carcinogens
        .map((c) => c.riskLevel.value)
        .reduce((a, b) => a > b ? a : b);

    return RiskLevel.fromValue(maxRisk);
  }

  bool _isMatch(String ingredient, Carcinogen carcinogen) {
    String normalizedName = _normalize(carcinogen.name);

    // Direct match
    if (ingredient.contains(normalizedName) ||
        normalizedName.contains(ingredient)) {
      return true;
    }

    // Check aliases
    for (String alias in carcinogen.aliases) {
      String normalizedAlias = _normalize(alias);
      if (ingredient.contains(normalizedAlias) ||
          normalizedAlias.contains(ingredient)) {
        return true;
      }
    }

    // Fuzzy matching for partial matches
    if (_fuzzyMatch(ingredient, normalizedName)) {
      return true;
    }

    return false;
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();
  }

  bool _fuzzyMatch(String a, String b) {
    // Simple Levenshtein distance check
    if (a.length < 4 || b.length < 4) return false;

    int distance = _levenshteinDistance(a, b);
    int maxLength = a.length > b.length ? a.length : b.length;

    // Allow 20% difference
    return distance <= maxLength * 0.2;
  }

  int _levenshteinDistance(String a, String b) {
    List<List<int>> dp = List.generate(
      a.length + 1,
      (_) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) dp[i][0] = i;
    for (int j = 0; j <= b.length; j++) dp[0][j] = j;

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        int cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[a.length][b.length];
  }
}
```

### Open Food Facts API Client (features/product/data/datasources/product_remote_datasource.dart)

```dart
import 'package:dio/dio.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<ProductModel> getProductByBarcode(String barcode);
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final Dio dio;

  ProductRemoteDataSourceImpl({required this.dio});

  @override
  Future<ProductModel> getProductByBarcode(String barcode) async {
    try {
      final response = await dio.get(
        '/product/$barcode',
        queryParameters: {
          'fields': 'code,product_name,brands,ingredients_text,ingredients,image_url,nutriments',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 1) {
        return ProductModel.fromJson(response.data['product']);
      } else {
        throw Exception('Product not found');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }
}
```

### Product Model (features/product/data/models/product_model.dart)

```dart
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
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    List<Ingredient> ingredients = [];

    if (json['ingredients'] != null) {
      ingredients = (json['ingredients'] as List)
          .map((i) => IngredientModel.fromJson(i))
          .toList();
    }

    return ProductModel(
      barcode: json['code'] ?? '',
      name: json['product_name'] ?? 'Unknown Product',
      brand: json['brands'],
      imageUrl: json['image_url'],
      ingredients: ingredients,
      ingredientsText: json['ingredients_text'],
      nutriments: json['nutriments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': barcode,
      'product_name': name,
      'brands': brand,
      'image_url': imageUrl,
      'ingredients_text': ingredientsText,
      'nutriments': nutriments,
    };
  }
}

class IngredientModel extends Ingredient {
  const IngredientModel({
    required super.id,
    required super.name,
    super.percent,
    super.isVegan,
    super.isVegetarian,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      id: json['id'] ?? '',
      name: json['text'] ?? json['id'] ?? '',
      percent: json['percent_estimate']?.toDouble(),
      isVegan: json['vegan'] != 'no',
      isVegetarian: json['vegetarian'] != 'no',
    );
  }
}
```

### Scanner BLoC (features/scanner/presentation/bloc/scanner_bloc.dart)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ScannerEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartScanning extends ScannerEvent {}
class StopScanning extends ScannerEvent {}
class BarcodeDetected extends ScannerEvent {
  final String barcode;
  BarcodeDetected(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

// States
abstract class ScannerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {}
class ScannerReady extends ScannerState {}
class Scanning extends ScannerState {}
class BarcodeScanned extends ScannerState {
  final String barcode;
  BarcodeScanned(this.barcode);

  @override
  List<Object?> get props => [barcode];
}
class ScannerError extends ScannerState {
  final String message;
  ScannerError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc() : super(ScannerInitial()) {
    on<StartScanning>(_onStartScanning);
    on<StopScanning>(_onStopScanning);
    on<BarcodeDetected>(_onBarcodeDetected);
  }

  void _onStartScanning(StartScanning event, Emitter<ScannerState> emit) {
    emit(Scanning());
  }

  void _onStopScanning(StopScanning event, Emitter<ScannerState> emit) {
    emit(ScannerReady());
  }

  void _onBarcodeDetected(BarcodeDetected event, Emitter<ScannerState> emit) {
    emit(BarcodeScanned(event.barcode));
  }
}
```

### Product BLoC (features/product/presentation/bloc/product_bloc.dart)

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/product.dart';
import '../../domain/usecases/get_product_by_barcode.dart';

// Events
abstract class ProductEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadProduct extends ProductEvent {
  final String barcode;
  LoadProduct(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

class ClearProduct extends ProductEvent {}

// States
abstract class ProductState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}
class ProductLoading extends ProductState {}
class ProductLoaded extends ProductState {
  final Product product;
  ProductLoaded(this.product);

  @override
  List<Object?> get props => [product];
}
class ProductError extends ProductState {
  final String message;
  ProductError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final GetProductByBarcode getProductByBarcode;

  ProductBloc({required this.getProductByBarcode}) : super(ProductInitial()) {
    on<LoadProduct>(_onLoadProduct);
    on<ClearProduct>(_onClearProduct);
  }

  Future<void> _onLoadProduct(
    LoadProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());

    final result = await getProductByBarcode(event.barcode);

    result.fold(
      (failure) => emit(ProductError(failure.message)),
      (product) => emit(ProductLoaded(product)),
    );
  }

  void _onClearProduct(ClearProduct event, Emitter<ProductState> emit) {
    emit(ProductInitial());
  }
}
```

---

## UI Components

### App Theme (core/theme/app_theme.dart)

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF6200EE);
  static const secondary = Color(0xFF03DAC6);
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const error = Color(0xFFB00020);

  // Risk level colors
  static const riskSafe = Color(0xFF4CAF50);
  static const riskLow = Color(0xFF8BC34A);
  static const riskMedium = Color(0xFFFFC107);
  static const riskHigh = Color(0xFFFF9800);
  static const riskCritical = Color(0xFFF44336);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
    );
  }
}
```

### Home Page (features/home/presentation/pages/home_page.dart)

```dart
import 'package:flutter/material.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../../history/presentation/pages/history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeContent(),
    const ScannerPage(),
    const HistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yuko',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Food Carcinogen Scanner',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Scan a product barcode to check\nfor potentially harmful ingredients',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to scanner
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Start Scanning'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Scanner Page (features/scanner/presentation/pages/scanner_page.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../bloc/scanner_bloc.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  late MobileScannerController _controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                return Icon(
                  state == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          _buildOverlay(),
          _buildInstructions(),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      setState(() => _isProcessing = true);

      context.read<ScannerBloc>().add(BarcodeDetected(barcode!.rawValue!));

      // Navigate to results or process barcode
      _navigateToResults(barcode.rawValue!);
    }
  }

  void _navigateToResults(String barcode) {
    // Navigate to product details page
    Navigator.pushNamed(context, '/product', arguments: barcode);
  }

  Widget _buildOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: const Text(
          'Position the barcode within the frame',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Results Page (features/product/presentation/pages/product_details_page.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/product.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';
import '../bloc/product_bloc.dart';
import '../widgets/risk_indicator.dart';
import '../widgets/ingredient_list.dart';

class ProductDetailsPage extends StatelessWidget {
  final String barcode;

  const ProductDetailsPage({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      builder: (context, state) {
        if (state is ProductLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProductError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ProductLoaded) {
          return _buildProductDetails(context, state.product);
        }

        return const Scaffold(
          body: Center(child: Text('Unknown state')),
        );
      },
    );
  }

  Widget _buildProductDetails(BuildContext context, Product product) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share product info
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product.imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product.brand != null)
                        Text(
                          product.brand!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Barcode: ${product.barcode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Risk Assessment Card
            const RiskIndicator(riskLevel: RiskLevel.medium),

            const SizedBox(height: 24),

            // Ingredients Section
            const Text(
              'Ingredients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            IngredientList(ingredients: product.ingredients),

            const SizedBox(height: 24),

            // Detected Carcinogens Section
            const Text(
              'Detected Concerns',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // CarcinogenList widget here
          ],
        ),
      ),
    );
  }
}
```

### Risk Indicator Widget (features/product/presentation/widgets/risk_indicator.dart)

```dart
import 'package:flutter/material.dart';
import '../../../carcinogen/domain/entities/carcinogen.dart';

class RiskIndicator extends StatelessWidget {
  final RiskLevel riskLevel;

  const RiskIndicator({super.key, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(riskLevel.color).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Color(riskLevel.color),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(),
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    riskLevel.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(riskLevel.color),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getDescription(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.warning;
      case RiskLevel.high:
        return Icons.error;
      case RiskLevel.critical:
        return Icons.dangerous;
    }
  }

  String _getDescription() {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'No known carcinogens detected in this product.';
      case RiskLevel.medium:
        return 'Contains substances possibly carcinogenic to humans.';
      case RiskLevel.high:
        return 'Contains substances probably carcinogenic to humans.';
      case RiskLevel.critical:
        return 'Contains substances known to be carcinogenic to humans.';
    }
  }
}
```

---

## Android Configuration

### AndroidManifest.xml Permissions

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera permission for barcode scanning -->
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-feature android:name="android.hardware.camera" android:required="true" />
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />

    <!-- Internet permission for API calls -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <!-- Vibration for haptic feedback -->
    <uses-permission android:name="android.permission.VIBRATE" />

    <application
        android:label="Yuko"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

### pubspec.yaml

```yaml
name: yuko
description: Food Carcinogen Scanner App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.4
  injectable: ^2.3.2
  
  # Network
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # Local Storage
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
  
  # Barcode Scanner
  mobile_scanner: ^3.5.5
  
  # UI
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Utils
  dartz: ^0.10.1
  intl: ^0.18.1
  permission_handler: ^11.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.5
  mockito: ^5.4.4
  build_runner: ^2.4.7
  injectable_generator: ^2.4.1
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/data/
    - assets/images/
```

---

## Testing Strategy

### Unit Test Example (test/core/utils/ingredient_parser_test.dart)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yuko/core/utils/ingredient_parser.dart';

void main() {
  group('IngredientParser', () {
    test('should parse comma-separated ingredients', () {
      const input = 'sugar, salt, water, flour';
      final result = IngredientParser.parse(input);

      expect(result, ['sugar', 'salt', 'water', 'flour']);
    });

    test('should remove percentages from ingredients', () {
      const input = 'sugar (50%), water (30%), salt (20%)';
      final result = IngredientParser.parse(input);

      expect(result.every((i) => !i.contains('%')), true);
    });

    test('should handle empty input', () {
      final result = IngredientParser.parse('');
      expect(result, isEmpty);
    });

    test('should normalize ingredient names', () {
      final normalized = IngredientParser.normalize('  SUGAR  ');
      expect(normalized, 'sugar');
    });
  });
}
```

### Widget Test Example (test/features/product/presentation/widgets/risk_indicator_test.dart)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuko/features/product/presentation/widgets/risk_indicator.dart';
import 'package:yuko/features/carcinogen/domain/entities/carcinogen.dart';

void main() {
  group('RiskIndicator', () {
    testWidgets('should display correct label for low risk', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.low),
          ),
        ),
      );

      expect(find.text('Low Risk'), findsOneWidget);
    });

    testWidgets('should display warning icon for medium risk', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskIndicator(riskLevel: RiskLevel.medium),
          ),
        ),
      );

      expect(find.byIcon(Icons.warning), findsOneWidget);
    });
  });
}
```

---

## Next Steps

After reviewing this plan, the implementation can proceed by switching to **Code mode** to:

1. Initialize the Flutter project with `flutter create yuko`
2. Set up the directory structure as defined
3. Implement each feature module following the clean architecture pattern
4. Create the carcinogen database JSON files
5. Build and test on Android device/emulator

Would you like to proceed with implementation?