import 'package:equatable/equatable.dart';

/// Configuration for a Gemini model including capabilities and fallback priority
class GeminiModelConfig extends Equatable {
  /// The model identifier (e.g., 'gemini-2.5-pro')
  final String modelName;

  /// Priority in fallback chain (1 = primary, 2 = secondary, etc.)
  final int priority;

  /// Human-readable description
  final String description;

  /// Whether this is an experimental/preview model
  final bool isExperimental;

  /// Maximum retry attempts for this model before moving to next
  final int maxRetries;

  /// Maximum input tokens (context window)
  final int contextWindow;

  /// Maximum output tokens
  final int maxOutputTokens;

  /// Estimated cost per 1K tokens (USD) - for analytics
  final double estimatedCostPer1kTokens;

  /// Model generation (e.g., '2.5', '2.0')
  final String generation;

  /// Whether model supports thinking/reasoning mode
  final bool supportsThinking;

  const GeminiModelConfig({
    required this.modelName,
    required this.priority,
    required this.description,
    this.isExperimental = false,
    this.maxRetries = 2,
    this.contextWindow = 1048576, // 1M tokens default for Gemini 2.x
    this.maxOutputTokens = 65536, // 65K tokens default
    this.estimatedCostPer1kTokens = 0.0001,
    this.generation = '2.5',
    this.supportsThinking = false,
  });

  @override
  List<Object?> get props => [
        modelName,
        priority,
        description,
        isExperimental,
        maxRetries,
        contextWindow,
        maxOutputTokens,
        estimatedCostPer1kTokens,
        generation,
        supportsThinking,
      ];

  /// Create copy with modified properties
  GeminiModelConfig copyWith({
    String? modelName,
    int? priority,
    String? description,
    bool? isExperimental,
    int? maxRetries,
    int? contextWindow,
    int? maxOutputTokens,
    double? estimatedCostPer1kTokens,
    String? generation,
    bool? supportsThinking,
  }) {
    return GeminiModelConfig(
      modelName: modelName ?? this.modelName,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      isExperimental: isExperimental ?? this.isExperimental,
      maxRetries: maxRetries ?? this.maxRetries,
      contextWindow: contextWindow ?? this.contextWindow,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      estimatedCostPer1kTokens:
          estimatedCostPer1kTokens ?? this.estimatedCostPer1kTokens,
      generation: generation ?? this.generation,
      supportsThinking: supportsThinking ?? this.supportsThinking,
    );
  }

  @override
  String toString() {
    return 'GeminiModelConfig{modelName: $modelName, priority: $priority, gen: $generation}';
  }
}

/// Predefined Gemini model configurations with fallback chain
class GeminiModels {
  GeminiModels._();

  /// Primary model: Gemini 2.5 Flash - Best price-performance balance
  static const primary = GeminiModelConfig(
    modelName: 'gemini-2.5-flash',
    priority: 1,
    description: 'Best price-performance for large-scale processing',
    generation: '2.5',
    contextWindow: 1048576,
    maxOutputTokens: 65536,
    estimatedCostPer1kTokens: 0.0001,
    supportsThinking: true,
  );

  /// Secondary model: Gemini 2.5 Pro - Most powerful
  static const secondary = GeminiModelConfig(
    modelName: 'gemini-2.5-pro',
    priority: 2,
    description: 'State-of-the-art thinking model for complex reasoning',
    generation: '2.5',
    contextWindow: 1048576,
    maxOutputTokens: 65536,
    estimatedCostPer1kTokens: 0.0005,
    supportsThinking: true,
  );

  /// Tertiary model: Gemini 2.5 Flash Lite - Faster and more cost-efficient
  static const tertiary = GeminiModelConfig(
    modelName: 'gemini-2.5-flash-lite',
    priority: 3,
    description: 'Fastest flash model optimized for cost-efficiency and high throughput',
    generation: '2.5',
    contextWindow: 1048576,
    maxOutputTokens: 65536,
    estimatedCostPer1kTokens: 0.00005,
    supportsThinking: true,
  );

  /// Final fallback: Gemini 2.0 Flash - Stable alternative
  static const finalFallback = GeminiModelConfig(
    modelName: 'gemini-2.0-flash',
    priority: 4,
    description: 'Stable 2.0 generation model as final fallback',
    generation: '2.0',
    contextWindow: 1048576,
    maxOutputTokens: 65536,
    estimatedCostPer1kTokens: 0.0001,
    supportsThinking: false,
  );

  /// Complete fallback chain in priority order
  static const fallbackChain = [
    primary,
    secondary,
    tertiary,
    finalFallback,
  ];

  /// Get model config by name
  static GeminiModelConfig? getByName(String modelName) {
    try {
      return fallbackChain.firstWhere((m) => m.modelName == modelName);
    } catch (e) {
      return null;
    }
  }

  /// Get next model in fallback chain
  static GeminiModelConfig? getNextModel(String currentModelName) {
    final current = getByName(currentModelName);
    if (current == null) return primary;

    final nextPriority = current.priority + 1;
    try {
      return fallbackChain.firstWhere((m) => m.priority == nextPriority);
    } catch (e) {
      return null; // No more fallback models
    }
  }

  /// Get all model names
  static List<String> get allModelNames =>
      fallbackChain.map((m) => m.modelName).toList();
}
