import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing and retrieving API keys
class ApiKeyService {
  final FlutterSecureStorage secureStorage;

  // Storage keys
  static const String _geminiKeyName = 'gemini_api_key';
  static const String _claudeKeyName = 'claude_api_key';
  static const String _openaiKeyName = 'openai_api_key';

  ApiKeyService({required this.secureStorage});

  /// Save Gemini API key
  Future<void> saveGeminiKey(String apiKey) async {
    await secureStorage.write(key: _geminiKeyName, value: apiKey);
  }

  /// Get Gemini API key
  Future<String?> getGeminiKey() async {
    return await secureStorage.read(key: _geminiKeyName);
  }

  /// Delete Gemini API key
  Future<void> deleteGeminiKey() async {
    await secureStorage.delete(key: _geminiKeyName);
  }

  /// Save Claude API key
  Future<void> saveClaudeKey(String apiKey) async {
    await secureStorage.write(key: _claudeKeyName, value: apiKey);
  }

  /// Get Claude API key
  Future<String?> getClaudeKey() async {
    return await secureStorage.read(key: _claudeKeyName);
  }

  /// Delete Claude API key
  Future<void> deleteClaudeKey() async {
    await secureStorage.delete(key: _claudeKeyName);
  }

  /// Save OpenAI API key
  Future<void> saveOpenAIKey(String apiKey) async {
    await secureStorage.write(key: _openaiKeyName, value: apiKey);
  }

  /// Get OpenAI API key
  Future<String?> getOpenAIKey() async {
    return await secureStorage.read(key: _openaiKeyName);
  }

  /// Delete OpenAI API key
  Future<void> deleteOpenAIKey() async {
    await secureStorage.delete(key: _openaiKeyName);
  }

  /// Check if Gemini key is configured
  Future<bool> hasGeminiKey() async {
    final key = await getGeminiKey();
    return key != null && key.isNotEmpty;
  }

  /// Check if Claude key is configured
  Future<bool> hasClaudeKey() async {
    final key = await getClaudeKey();
    return key != null && key.isNotEmpty;
  }

  /// Check if OpenAI key is configured
  Future<bool> hasOpenAIKey() async {
    final key = await getOpenAIKey();
    return key != null && key.isNotEmpty;
  }

  /// Save API key by provider name
  Future<void> saveApiKey(String keyName, String apiKey) async {
    switch (keyName) {
      case 'gemini_api_key':
        await saveGeminiKey(apiKey);
        break;
      case 'claude_api_key':
        await saveClaudeKey(apiKey);
        break;
      case 'openai_api_key':
        await saveOpenAIKey(apiKey);
        break;
      default:
        throw ArgumentError('Unknown API key name: $keyName');
    }
  }

  /// Get API key by provider name
  Future<String?> getApiKey(String keyName) async {
    switch (keyName) {
      case 'gemini_api_key':
        return await getGeminiKey();
      case 'claude_api_key':
        return await getClaudeKey();
      case 'openai_api_key':
        return await getOpenAIKey();
      default:
        return null;
    }
  }

  /// Delete API key by provider name
  Future<void> deleteApiKey(String keyName) async {
    switch (keyName) {
      case 'gemini_api_key':
        await deleteGeminiKey();
        break;
      case 'claude_api_key':
        await deleteClaudeKey();
        break;
      case 'openai_api_key':
        await deleteOpenAIKey();
        break;
      default:
        throw ArgumentError('Unknown API key name: $keyName');
    }
  }

  /// Clear all API keys
  Future<void> clearAllKeys() async {
    await Future.wait([
      deleteGeminiKey(),
      deleteClaudeKey(),
      deleteOpenAIKey(),
    ]);
  }
}
