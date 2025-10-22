import '../../features/ai_chat/data/models/gemini_model_config.dart';
import '../utils/logger.dart';

/// Manages Gemini model selection, fallback logic, and failure tracking
class GeminiModelManager {
  /// Track models that have failed recently with cooldown expiry time
  final Map<String, DateTime> _failedModels = {};

  /// Track usage count per model for analytics
  final Map<String, int> _modelUsageCount = {};

  /// Track success count per model
  final Map<String, int> _modelSuccessCount = {};

  /// Track failure count per model
  final Map<String, int> _modelFailureCount = {};

  /// Last successfully used model
  String? _lastSuccessfulModel;

  /// Last attempted model
  String? _lastAttemptedModel;

  /// Get the last successfully used model name
  String? get lastSuccessfulModel => _lastSuccessfulModel;

  /// Get the last attempted model name
  String? get lastAttemptedModel => _lastAttemptedModel;

  /// Get next available model in fallback chain
  ///
  /// [excludeModel] - Optional model name to exclude from selection
  /// [currentAttempt] - Current retry attempt number (0-based)
  ///
  /// Returns the next available model config, or null if all models exhausted
  GeminiModelConfig? getNextModel({
    String? excludeModel,
    int currentAttempt = 0,
  }) {
    // Start from primary and go through fallback chain
    for (final model in GeminiModels.fallbackChain) {
      // Skip excluded model
      if (model.modelName == excludeModel) {
        continue;
      }

      // Skip models in cooldown
      if (!isModelAvailable(model.modelName)) {
        AppLogger.w(
          '⏸️  Model ${model.modelName} is in cooldown, skipping',
        );
        continue;
      }

      // Skip if already attempted too many times
      final failureCount = _modelFailureCount[model.modelName] ?? 0;
      if (failureCount >= model.maxRetries) {
        AppLogger.w(
          '⏸️  Model ${model.modelName} exceeded max retries ($failureCount/${model.maxRetries})',
        );
        continue;
      }

      AppLogger.i('✅ Selected model: ${model.modelName} (priority: ${model.priority})');
      _lastAttemptedModel = model.modelName;
      return model;
    }

    // All models exhausted or in cooldown
    AppLogger.e('❌ No available models in fallback chain');
    return null;
  }

  /// Mark model as failed and put in cooldown
  ///
  /// [modelName] - Name of the failed model
  /// [cooldown] - Duration to keep model in cooldown (default: 5 minutes)
  void markModelFailed(String modelName, [Duration? cooldown]) {
    final cooldownDuration = cooldown ?? const Duration(minutes: 5);
    final expiryTime = DateTime.now().add(cooldownDuration);

    _failedModels[modelName] = expiryTime;
    _modelFailureCount[modelName] = (_modelFailureCount[modelName] ?? 0) + 1;

    AppLogger.w(
      '❌ Model $modelName marked as failed (cooldown until ${expiryTime.toLocal()})',
    );
    AppLogger.i(
      '📊 Failure count for $modelName: ${_modelFailureCount[modelName]}',
    );
  }

  /// Mark model as successfully used
  ///
  /// [modelName] - Name of the successful model
  void markModelSuccess(String modelName) {
    _lastSuccessfulModel = modelName;
    _modelUsageCount[modelName] = (_modelUsageCount[modelName] ?? 0) + 1;
    _modelSuccessCount[modelName] = (_modelSuccessCount[modelName] ?? 0) + 1;

    AppLogger.i('✅ Model $modelName succeeded');
    AppLogger.i(
      '📊 Success count for $modelName: ${_modelSuccessCount[modelName]}',
    );
  }

  /// Check if model is available (not in cooldown)
  ///
  /// [modelName] - Name of the model to check
  ///
  /// Returns true if model is available, false if in cooldown
  bool isModelAvailable(String modelName) {
    if (!_failedModels.containsKey(modelName)) {
      return true;
    }

    final expiryTime = _failedModels[modelName]!;
    final now = DateTime.now();

    // Check if cooldown has expired
    if (now.isAfter(expiryTime)) {
      _failedModels.remove(modelName);
      AppLogger.i('✅ Model $modelName cooldown expired, now available');
      return true;
    }

    return false;
  }

  /// Reset all cooldowns and failure counts
  void resetCooldowns() {
    final count = _failedModels.length;
    _failedModels.clear();
    _modelFailureCount.clear();

    AppLogger.i('🔄 Reset $count model cooldowns');
  }

  /// Reset usage statistics
  void resetStats() {
    _modelUsageCount.clear();
    _modelSuccessCount.clear();
    _modelFailureCount.clear();
    _lastSuccessfulModel = null;
    _lastAttemptedModel = null;

    AppLogger.i('🔄 Reset all model statistics');
  }

  /// Get model usage statistics
  ///
  /// Returns a map of model names to usage counts
  Map<String, int> getModelStats() {
    return Map.unmodifiable(_modelUsageCount);
  }

  /// Get model success statistics
  ///
  /// Returns a map of model names to success counts
  Map<String, int> getSuccessStats() {
    return Map.unmodifiable(_modelSuccessCount);
  }

  /// Get model failure statistics
  ///
  /// Returns a map of model names to failure counts
  Map<String, int> getFailureStats() {
    return Map.unmodifiable(_modelFailureCount);
  }

  /// Get success rate for a model
  ///
  /// [modelName] - Name of the model
  ///
  /// Returns success rate as percentage (0-100), or null if no data
  double? getSuccessRate(String modelName) {
    final success = _modelSuccessCount[modelName] ?? 0;
    final failure = _modelFailureCount[modelName] ?? 0;
    final total = success + failure;

    if (total == 0) return null;
    return (success / total) * 100;
  }

  /// Get comprehensive statistics for all models
  Map<String, Map<String, dynamic>> getAllStats() {
    final stats = <String, Map<String, dynamic>>{};

    for (final model in GeminiModels.fallbackChain) {
      final modelName = model.modelName;
      final usage = _modelUsageCount[modelName] ?? 0;
      final success = _modelSuccessCount[modelName] ?? 0;
      final failure = _modelFailureCount[modelName] ?? 0;
      final successRate = getSuccessRate(modelName);
      final isAvailable = isModelAvailable(modelName);

      stats[modelName] = {
        'usage_count': usage,
        'success_count': success,
        'failure_count': failure,
        'success_rate': successRate,
        'is_available': isAvailable,
        'priority': model.priority,
        'generation': model.generation,
      };
    }

    return stats;
  }

  /// Print current status to logs
  void logStatus() {
    AppLogger.i('📊 Gemini Model Manager Status:');
    AppLogger.i('   Last successful: $_lastSuccessfulModel');
    AppLogger.i('   Last attempted: $_lastAttemptedModel');
    AppLogger.i('   Failed models in cooldown: ${_failedModels.length}');

    for (final entry in _failedModels.entries) {
      final remaining = entry.value.difference(DateTime.now());
      AppLogger.i(
        '      - ${entry.key}: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s remaining',
      );
    }

    AppLogger.i('   Model Statistics:');
    for (final model in GeminiModels.fallbackChain) {
      final usage = _modelUsageCount[model.modelName] ?? 0;
      final success = _modelSuccessCount[model.modelName] ?? 0;
      final failure = _modelFailureCount[model.modelName] ?? 0;
      final rate = getSuccessRate(model.modelName);

      AppLogger.i(
        '      - ${model.modelName}: ${usage} uses, ${success} ✓, ${failure} ✗ (${rate?.toStringAsFixed(1) ?? 'N/A'}%)',
      );
    }
  }
}
