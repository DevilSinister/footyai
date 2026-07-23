import '../models/ai_prediction.dart';
import 'api_service.dart';

class PredictionService {
  static Future<List<AIPrediction>> getPredictions() async {
    return await ApiService.fetchPredictions();
  }
}