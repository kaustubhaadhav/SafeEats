import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/carcinogen_matcher.dart';
import '../../../../core/utils/ingredient_parser.dart';
import '../entities/carcinogen.dart';
import '../repositories/carcinogen_repository.dart';

class AnalysisResult {
  final List<CarcinogenMatchResult> matches;
  final List<Carcinogen> uniqueCarcinogens;
  final RiskLevel overallRisk;
  final List<String> parsedIngredients;

  AnalysisResult({
    required this.matches,
    required this.uniqueCarcinogens,
    required this.overallRisk,
    required this.parsedIngredients,
  });

  bool get hasCarcinogens => uniqueCarcinogens.isNotEmpty;
  
  int get carcinogenCount => uniqueCarcinogens.length;
  
  List<Carcinogen> get criticalCarcinogens => 
      uniqueCarcinogens.where((c) => c.riskLevel == RiskLevel.critical).toList();
  
  List<Carcinogen> get highRiskCarcinogens => 
      uniqueCarcinogens.where((c) => c.riskLevel == RiskLevel.high).toList();
}

class CheckIngredientsForCarcinogens {
  final CarcinogenRepository repository;

  CheckIngredientsForCarcinogens(this.repository);

  Future<Either<Failure, AnalysisResult>> call(String? ingredientsText) async {
    if (ingredientsText == null || ingredientsText.isEmpty) {
      return Right(AnalysisResult(
        matches: [],
        uniqueCarcinogens: [],
        overallRisk: RiskLevel.safe,
        parsedIngredients: [],
      ));
    }

    // Get all carcinogens from database
    final carcinogensResult = await repository.getAllCarcinogens();
    
    return carcinogensResult.fold(
      (failure) => Left(failure),
      (carcinogens) {
        // Parse ingredients
        final parsedIngredients = IngredientParser.parse(ingredientsText);
        
        // Also extract E-numbers
        final eNumbers = IngredientParser.extractENumbers(ingredientsText);
        final allIngredients = [...parsedIngredients, ...eNumbers];
        
        // Match against carcinogens
        final matcher = CarcinogenMatcher(carcinogens);
        final matches = matcher.findMatches(allIngredients);
        final uniqueCarcinogens = matcher.getUniqueCarcinogens(matches);
        final overallRisk = matcher.calculateOverallRisk(uniqueCarcinogens);
        
        return Right(AnalysisResult(
          matches: matches,
          uniqueCarcinogens: uniqueCarcinogens,
          overallRisk: overallRisk,
          parsedIngredients: parsedIngredients,
        ));
      },
    );
  }
}