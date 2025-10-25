import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for retrieving API keys from environment variables
class ApiKeyService {
  const ApiKeyService();

  /// Get Gemini API key from environment
  Future<String?> getGeminiKey() async {
    return dotenv.env['GEMINI_API_KEY'];
  }

  /// Get Claude API key from environment
  Future<String?> getClaudeKey() async {
    return dotenv.env['CLAUDE_API_KEY'];
  }

  /// Get OpenAI API key from environment
  Future<String?> getOpenAIKey() async {
    return dotenv.env['OPENAI_API_KEY'];
  }

  /// Check if Gemini key is configured
  Future<bool> hasGeminiKey() async {
    final key = await getGeminiKey();
    return key != null && key.isNotEmpty && key != 'your_gemini_api_key_here';
  }

  /// Check if Claude key is configured
  Future<bool> hasClaudeKey() async {
    final key = await getClaudeKey();
    return key != null && key.isNotEmpty && key != 'your_claude_api_key_here';
  }

  /// Check if OpenAI key is configured
  Future<bool> hasOpenAIKey() async {
    final key = await getOpenAIKey();
    return key != null && key.isNotEmpty && !key.startsWith('your_');
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

}
