import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:connectivity_plus/connectivity_plus.dart';

// Core
import 'core/network/api_client.dart';
import 'core/network/network_info.dart';

// Features - Scanner
import 'features/scanner/presentation/bloc/scanner_bloc.dart';

// Features - Product
import 'features/product/data/datasources/product_remote_datasource.dart';
import 'features/product/data/datasources/product_local_datasource.dart';
import 'features/product/data/repositories/product_repository_impl.dart';
import 'features/product/domain/repositories/product_repository.dart';
import 'features/product/domain/usecases/get_product_by_barcode.dart';
import 'features/product/presentation/bloc/product_bloc.dart';

// Features - Carcinogen
import 'features/carcinogen/data/datasources/carcinogen_local_datasource.dart';
import 'features/carcinogen/data/repositories/carcinogen_repository_impl.dart';
import 'features/carcinogen/domain/repositories/carcinogen_repository.dart';
import 'features/carcinogen/domain/usecases/check_ingredients_for_carcinogens.dart';
import 'features/carcinogen/domain/usecases/get_all_carcinogens.dart';
import 'features/carcinogen/presentation/bloc/carcinogen_bloc.dart';

// Features - History
import 'features/history/data/datasources/history_local_datasource.dart';
import 'features/history/data/repositories/history_repository_impl.dart';
import 'features/history/domain/repositories/history_repository.dart';
import 'features/history/domain/usecases/get_scan_history.dart';
import 'features/history/domain/usecases/save_scan.dart';
import 'features/history/domain/usecases/delete_scan.dart';
import 'features/history/presentation/bloc/history_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Core
  // Network
  sl.registerLazySingleton(() => Dio(BaseOptions(
    baseUrl: 'https://world.openfoodfacts.org/api/v2',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'User-Agent': 'Yuko - Food Carcinogen Scanner - Android - Version 1.0',
    },
  )));
  
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));

  // Database
  final database = await _initDatabase();
  sl.registerSingleton<Database>(database);

  //! Features - Scanner
  sl.registerFactory(() => ScannerBloc());

  //! Features - Product
  // Data sources
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(apiClient: sl()),
  );
  sl.registerLazySingleton<ProductLocalDataSource>(
    () => ProductLocalDataSourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetProductByBarcode(sl()));

  // BLoC
  sl.registerFactory(() => ProductBloc(
    getProductByBarcode: sl(),
    checkIngredientsForCarcinogens: sl(),
    saveScan: sl(),
  ));

  //! Features - Carcinogen
  // Data sources
  sl.registerLazySingleton<CarcinogenLocalDataSource>(
    () => CarcinogenLocalDataSourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<CarcinogenRepository>(
    () => CarcinogenRepositoryImpl(localDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => CheckIngredientsForCarcinogens(sl()));
  sl.registerLazySingleton(() => GetAllCarcinogens(sl()));

  // BLoC
  sl.registerFactory(() => CarcinogenBloc(
    getAllCarcinogens: sl(),
  ));

  //! Features - History
  // Data sources
  sl.registerLazySingleton<HistoryLocalDatasource>(
    () => HistoryLocalDatasourceImpl(database: sl()),
  );

  // Repository
  sl.registerLazySingleton<HistoryRepository>(
    () => HistoryRepositoryImpl(localDatasource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetScanHistory(sl()));
  sl.registerLazySingleton(() => SaveScan(sl()));
  sl.registerLazySingleton(() => DeleteScan(sl()));

  // BLoC
  sl.registerFactory(() => HistoryBloc(
    getScanHistory: sl(),
    deleteScan: sl(),
  ));

  // Initialize carcinogen database
  await _initCarcinogenData();
}

Future<Database> _initDatabase() async {
  final databasesPath = await getDatabasesPath();
  final dbPath = path.join(databasesPath, 'yuko.db');

  return openDatabase(
    dbPath,
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE carcinogens (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          aliases TEXT,
          cas_number TEXT,
          source TEXT NOT NULL,
          classification TEXT,
          risk_level INTEGER NOT NULL,
          description TEXT,
          common_foods TEXT,
          source_url TEXT
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
          scanned_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE cached_products (
          barcode TEXT PRIMARY KEY,
          product_data TEXT NOT NULL,
          cached_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX idx_scan_history_barcode ON scan_history(barcode)
      ''');
      
      await db.execute('''
        CREATE INDEX idx_scan_history_scanned_at ON scan_history(scanned_at)
      ''');
    },
  );
}

Future<void> _initCarcinogenData() async {
  final db = sl<Database>();
  
  // Check if carcinogens already exist
  final count = Sqflite.firstIntValue(
    await db.rawQuery('SELECT COUNT(*) FROM carcinogens'),
  );
  
  if (count != null && count > 0) return;

  // Insert IARC carcinogens
  final iarcCarcinogens = [
    {
      'id': 'iarc_001',
      'name': 'Acrylamide',
      'aliases': '["acrylic amide", "2-propenamide", "ethylene carboxamide"]',
      'cas_number': '79-06-1',
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Formed when starchy foods are cooked at high temperatures. Found in french fries, potato chips, bread, and coffee.',
      'common_foods': '["french fries", "potato chips", "bread", "coffee", "crackers", "breakfast cereals"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_002',
      'name': 'Aflatoxins',
      'aliases': '["aflatoxin b1", "aflatoxin b2", "aflatoxin g1", "aflatoxin g2"]',
      'cas_number': '1402-68-2',
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Naturally occurring mycotoxins produced by Aspergillus fungi. Can contaminate peanuts, corn, and tree nuts.',
      'common_foods': '["peanuts", "corn", "tree nuts", "cottonseed", "spices"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_003',
      'name': 'Alcohol',
      'aliases': '["ethyl alcohol", "ethanol", "alcoholic beverages"]',
      'cas_number': '64-17-5',
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Consumption of alcoholic beverages is carcinogenic. Associated with cancers of mouth, pharynx, larynx, esophagus, liver, and breast.',
      'common_foods': '["beer", "wine", "spirits", "liquor"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_004',
      'name': 'Arsenic',
      'aliases': '["arsenite", "arsenate", "inorganic arsenic"]',
      'cas_number': '7440-38-2',
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Can be found in rice, drinking water, and some seafood. Chronic exposure linked to skin, lung, and bladder cancer.',
      'common_foods': '["rice", "rice products", "some seafood", "apple juice"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_005',
      'name': 'Benzene',
      'aliases': '["benzol", "phenyl hydride"]',
      'cas_number': '71-43-2',
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Can form in soft drinks containing benzoic acid and ascorbic acid. Causes leukemia.',
      'common_foods': '["some soft drinks", "preserved foods with benzoates"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_006',
      'name': 'Benzo[a]pyrene',
      'aliases': '["bap", "3,4-benzopyrene"]',
      'cas_number': '50-32-8',
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Polycyclic aromatic hydrocarbon formed during grilling, smoking, and charring of meat.',
      'common_foods': '["grilled meat", "smoked fish", "charred foods", "barbecued foods"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_007',
      'name': 'Cadmium',
      'aliases': '["cadmium compounds"]',
      'cas_number': '7440-43-9',
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Heavy metal found in shellfish, organ meats, and vegetables grown in contaminated soil.',
      'common_foods': '["shellfish", "organ meats", "leafy vegetables", "potatoes"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_008',
      'name': 'Formaldehyde',
      'aliases': '["formalin", "methyl aldehyde", "methanal"]',
      'cas_number': '50-00-0',
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Can be found naturally in some foods and may be illegally added as a preservative.',
      'common_foods': '["some preserved foods", "dried foods"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_009',
      'name': 'Heterocyclic Amines',
      'aliases': '["hca", "heterocyclic aromatic amines", "haas", "phip", "meiqx"]',
      'cas_number': null,
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Formed when muscle meat is cooked at high temperatures.',
      'common_foods': '["pan-fried meat", "grilled meat", "barbecued meat", "well-done meat"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_010',
      'name': 'Lead',
      'aliases': '["lead compounds", "plumbum"]',
      'cas_number': '7439-92-1',
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Heavy metal that can contaminate food through soil, water, or processing equipment.',
      'common_foods': '["leafy vegetables", "root vegetables", "some candies", "certain spices"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_011',
      'name': 'Nitrates',
      'aliases': '["sodium nitrate", "potassium nitrate", "e251", "e252"]',
      'cas_number': '7631-99-4',
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Used as preservatives in processed meats. Can form carcinogenic nitrosamines.',
      'common_foods': '["bacon", "hot dogs", "ham", "sausages", "deli meats"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_012',
      'name': 'Nitrites',
      'aliases': '["sodium nitrite", "potassium nitrite", "e249", "e250"]',
      'cas_number': '7632-00-0',
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Preservative in cured meats that can form nitrosamines.',
      'common_foods': '["cured meats", "bacon", "hot dogs", "deli meats"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_013',
      'name': 'N-Nitrosamines',
      'aliases': '["nitrosamines", "ndma", "ndea"]',
      'cas_number': null,
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Formed from nitrites during cooking or digestion. Found in cured meats and some beers.',
      'common_foods': '["cured meats", "beer", "smoked fish", "processed cheese"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_014',
      'name': 'Ochratoxin A',
      'aliases': '["ota", "ochratoxin"]',
      'cas_number': '303-47-9',
      'source': 'IARC',
      'classification': 'Group 2B',
      'risk_level': 2,
      'description': 'Mycotoxin found in cereals, dried fruits, wine, and coffee.',
      'common_foods': '["cereals", "dried fruits", "wine", "coffee", "spices", "grape juice"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_015',
      'name': 'Polycyclic Aromatic Hydrocarbons',
      'aliases': '["pahs", "polyaromatic hydrocarbons"]',
      'cas_number': null,
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Formed during incomplete combustion. Found in smoked, grilled, and charred foods.',
      'common_foods': '["smoked meats", "grilled foods", "charred foods", "smoked fish"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_016',
      'name': 'Processed Meat',
      'aliases': '["processed meats", "cured meat", "smoked meat"]',
      'cas_number': null,
      'source': 'IARC',
      'classification': 'Group 1',
      'risk_level': 4,
      'description': 'Meat transformed through salting, curing, fermentation, or smoking.',
      'common_foods': '["hot dogs", "bacon", "ham", "sausages", "corned beef", "beef jerky"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_017',
      'name': 'Red Meat',
      'aliases': '["mammalian meat", "beef", "pork", "lamb"]',
      'cas_number': null,
      'source': 'IARC',
      'classification': 'Group 2A',
      'risk_level': 3,
      'description': 'Unprocessed mammalian muscle meat.',
      'common_foods': '["beef", "pork", "lamb", "veal", "mutton"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_018',
      'name': 'Titanium Dioxide',
      'aliases': '["e171", "tio2", "titanium white"]',
      'cas_number': '13463-67-7',
      'source': 'IARC',
      'classification': 'Group 2B',
      'risk_level': 2,
      'description': 'Food additive used as whitening agent. Banned in EU as food additive since 2022.',
      'common_foods': '["candies", "chewing gum", "white sauces", "icing"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_019',
      'name': 'Furan',
      'aliases': '["furfuran", "oxole"]',
      'cas_number': '110-00-9',
      'source': 'IARC',
      'classification': 'Group 2B',
      'risk_level': 2,
      'description': 'Formed during thermal treatment of food. Found in coffee and canned foods.',
      'common_foods': '["coffee", "canned foods", "jarred baby food", "soups", "sauces"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
    {
      'id': 'iarc_020',
      'name': '3-MCPD',
      'aliases': '["3-monochloropropane-1,2-diol", "3-chloropropane-1,2-diol"]',
      'cas_number': '96-24-2',
      'source': 'IARC',
      'classification': 'Group 2B',
      'risk_level': 2,
      'description': 'Forms during food processing, especially in refined oils and soy sauce.',
      'common_foods': '["refined oils", "soy sauce", "hydrolyzed vegetable protein", "bread"]',
      'source_url': 'https://monographs.iarc.who.int/',
    },
  ];

  // Insert Prop 65 carcinogens
  final prop65Carcinogens = [
    {
      'id': 'prop65_001',
      'name': 'Bisphenol A',
      'aliases': '["bpa", "bisphenol-a"]',
      'cas_number': '80-05-7',
      'source': 'PROP65',
      'classification': 'Reproductive Toxicant',
      'risk_level': 2,
      'description': 'Can leach from food containers and can linings.',
      'common_foods': '["canned foods", "plastic containers"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_002',
      'name': 'Mercury',
      'aliases': '["methylmercury", "mercuric"]',
      'cas_number': '7439-97-6',
      'source': 'PROP65',
      'classification': 'Reproductive Toxicant',
      'risk_level': 3,
      'description': 'Methylmercury compounds found in fish.',
      'common_foods': '["large fish", "tuna", "swordfish", "shark", "king mackerel"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_003',
      'name': 'Phthalates',
      'aliases': '["dehp", "di-2-ethylhexyl phthalate", "diethyl phthalate"]',
      'cas_number': '117-81-7',
      'source': 'PROP65',
      'classification': 'Reproductive Toxicant',
      'risk_level': 2,
      'description': 'Plasticizer that can migrate into food from packaging.',
      'common_foods': '["fatty foods in plastic", "dairy products", "processed foods"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_004',
      'name': 'Potassium Bromate',
      'aliases': '["bromate", "potassium bromate"]',
      'cas_number': '7758-01-2',
      'source': 'PROP65',
      'classification': 'Carcinogen',
      'risk_level': 3,
      'description': 'Bread additive banned in many countries but still used in some.',
      'common_foods': '["some breads", "flour products"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_005',
      'name': 'Butylated Hydroxyanisole',
      'aliases': '["bha", "e320"]',
      'cas_number': '25013-16-5',
      'source': 'PROP65',
      'classification': 'Carcinogen',
      'risk_level': 2,
      'description': 'Antioxidant preservative used in foods.',
      'common_foods': '["chips", "cereals", "butter", "baked goods", "snack foods"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_006',
      'name': 'Butylated Hydroxytoluene',
      'aliases': '["bht", "e321"]',
      'cas_number': '128-37-0',
      'source': 'PROP65',
      'classification': 'Possible Carcinogen',
      'risk_level': 2,
      'description': 'Antioxidant preservative similar to BHA.',
      'common_foods': '["cereals", "snack foods", "chewing gum", "butter"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_007',
      'name': 'Azodicarbonamide',
      'aliases': '["ada", "azodicarbonamide"]',
      'cas_number': '123-77-3',
      'source': 'PROP65',
      'classification': 'Respiratory Sensitizer',
      'risk_level': 2,
      'description': 'Dough conditioner banned in EU and Australia.',
      'common_foods': '["some breads", "baked goods"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_008',
      'name': 'Brominated Vegetable Oil',
      'aliases': '["bvo", "brominated oil"]',
      'cas_number': '8016-94-2',
      'source': 'PROP65',
      'classification': 'Toxicant',
      'risk_level': 2,
      'description': 'Emulsifier in some citrus-flavored drinks. Being phased out.',
      'common_foods': '["some citrus drinks", "sports drinks"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_009',
      'name': 'Carrageenan',
      'aliases': '["degraded carrageenan", "e407"]',
      'cas_number': '9000-07-1',
      'source': 'PROP65',
      'classification': 'Possible Carcinogen',
      'risk_level': 2,
      'description': 'Thickening agent, degraded form may be concerning.',
      'common_foods': '["dairy products", "plant milks", "ice cream", "deli meats"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_010',
      'name': 'Aspartame',
      'aliases': '["e951", "nutrasweet", "equal"]',
      'cas_number': '22839-47-0',
      'source': 'PROP65',
      'classification': 'Possibly Carcinogenic',
      'risk_level': 2,
      'description': 'Artificial sweetener classified as possibly carcinogenic by IARC in 2023.',
      'common_foods': '["diet sodas", "sugar-free products", "chewing gum", "yogurt"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_011',
      'name': 'Caramel Color',
      'aliases': '["4-mei", "4-methylimidazole", "e150d"]',
      'cas_number': '822-36-6',
      'source': 'PROP65',
      'classification': 'Carcinogen',
      'risk_level': 2,
      'description': '4-Methylimidazole found in some caramel coloring.',
      'common_foods': '["colas", "dark sodas", "some beers", "soy sauce"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_012',
      'name': 'Glyphosate',
      'aliases': '["roundup", "herbicide residue"]',
      'cas_number': '1071-83-6',
      'source': 'PROP65',
      'classification': 'Carcinogen',
      'risk_level': 3,
      'description': 'Herbicide residue found in some foods.',
      'common_foods': '["oats", "cereals", "wheat products", "some produce"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_013',
      'name': 'Red Dye No. 3',
      'aliases': '["erythrosine", "e127", "fd&c red no. 3"]',
      'cas_number': '16423-68-0',
      'source': 'PROP65',
      'classification': 'Carcinogen',
      'risk_level': 2,
      'description': 'Food coloring linked to thyroid tumors in animals.',
      'common_foods': '["candies", "maraschino cherries", "some medications"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_014',
      'name': 'Red Dye No. 40',
      'aliases': '["allura red", "e129", "fd&c red no. 40"]',
      'cas_number': '25956-17-6',
      'source': 'PROP65',
      'classification': 'Possible Carcinogen',
      'risk_level': 2,
      'description': 'Most common red food dye, some concerns about contaminants.',
      'common_foods': '["candies", "cereals", "beverages", "snacks"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_015',
      'name': 'Yellow Dye No. 5',
      'aliases': '["tartrazine", "e102", "fd&c yellow no. 5"]',
      'cas_number': '1934-21-0',
      'source': 'PROP65',
      'classification': 'Possible Concern',
      'risk_level': 1,
      'description': 'Food coloring that may cause allergic reactions.',
      'common_foods': '["candies", "cereals", "snacks", "beverages"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_016',
      'name': 'Yellow Dye No. 6',
      'aliases': '["sunset yellow", "e110", "fd&c yellow no. 6"]',
      'cas_number': '2783-94-0',
      'source': 'PROP65',
      'classification': 'Possible Concern',
      'risk_level': 1,
      'description': 'Food coloring with some health concerns.',
      'common_foods': '["candies", "beverages", "cereals", "snacks"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_017',
      'name': 'PFAS',
      'aliases': '["pfoa", "pfos", "forever chemicals", "perfluorinated compounds"]',
      'cas_number': '335-67-1',
      'source': 'PROP65',
      'classification': 'Carcinogen',
      'risk_level': 3,
      'description': 'Forever chemicals that can contaminate food through packaging.',
      'common_foods': '["fast food wrappers", "microwave popcorn bags", "some fish"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_018',
      'name': 'Propyl Paraben',
      'aliases': '["propylparaben", "e216"]',
      'cas_number': '94-13-3',
      'source': 'PROP65',
      'classification': 'Endocrine Disruptor',
      'risk_level': 2,
      'description': 'Preservative with endocrine disrupting properties.',
      'common_foods': '["some baked goods", "beverages", "processed foods"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_019',
      'name': 'Sodium Benzoate',
      'aliases': '["e211", "benzoate of soda"]',
      'cas_number': '532-32-1',
      'source': 'PROP65',
      'classification': 'Possible Concern',
      'risk_level': 2,
      'description': 'Preservative that can form benzene when combined with vitamin C.',
      'common_foods': '["soft drinks", "fruit juices", "pickles", "condiments"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
    {
      'id': 'prop65_020',
      'name': 'TBHQ',
      'aliases': '["tertiary butylhydroquinone", "e319"]',
      'cas_number': '1948-33-0',
      'source': 'PROP65',
      'classification': 'Possible Carcinogen',
      'risk_level': 2,
      'description': 'Antioxidant preservative used in processed foods.',
      'common_foods': '["fast food", "crackers", "chips", "frozen foods", "instant noodles"]',
      'source_url': 'https://oehha.ca.gov/proposition-65',
    },
  ];

  // Batch insert all carcinogens
  final batch = db.batch();
  
  for (final c in iarcCarcinogens) {
    batch.insert('carcinogens', c);
  }
  
  for (final c in prop65Carcinogens) {
    batch.insert('carcinogens', c);
  }
  
  await batch.commit(noResult: true);
}