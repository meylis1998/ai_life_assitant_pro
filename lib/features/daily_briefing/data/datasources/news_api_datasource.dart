import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/news_article_model.dart';

/// Remote data source for news data using NewsAPI.org
abstract class NewsApiDataSource {
  /// Get top news headlines
  Future<List<NewsArticleModel>> getTopHeadlines({
    String? country,
    String? category,
    int pageSize = 10,
  });

  /// Search news by keywords
  Future<List<NewsArticleModel>> searchNews({
    required String query,
    int pageSize = 10,
  });
}

class NewsApiDataSourceImpl implements NewsApiDataSource {
  final Dio dio;
  static const String _baseUrl = 'https://newsapi.org/v2';

  NewsApiDataSourceImpl({required this.dio});

  String get _apiKey => dotenv.env['NEWS_API_KEY'] ?? '';

  @override
  Future<List<NewsArticleModel>> getTopHeadlines({
    String? country,
    String? category,
    int pageSize = 10,
  }) async {
    try {
      final response = await dio.get(
        '$_baseUrl/top-headlines',
        queryParameters: {
          'apiKey': _apiKey,
          if (country != null) 'country': country,
          if (category != null) 'category': category,
          'pageSize': pageSize,
        },
      );

      final articlesJson = response.data['articles'] as List;

      return articlesJson
          .map((json) {
            final model = NewsArticleModel.fromNewsApi(json as Map<String, dynamic>);
            // Add category to the model
            return category != null
                ? model.copyWith(category: category)
                : model;
          })
          .where((article) => article.title.isNotEmpty && article.url.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error fetching news: $e');
    }
  }

  @override
  Future<List<NewsArticleModel>> searchNews({
    required String query,
    int pageSize = 10,
  }) async {
    try {
      final response = await dio.get(
        '$_baseUrl/everything',
        queryParameters: {
          'apiKey': _apiKey,
          'q': query,
          'pageSize': pageSize,
          'sortBy': 'publishedAt',
        },
      );

      final articlesJson = response.data['articles'] as List;

      return articlesJson
          .map((json) =>
              NewsArticleModel.fromNewsApi(json as Map<String, dynamic>))
          .where((article) => article.title.isNotEmpty && article.url.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error searching news: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return Exception('Invalid API key');
        } else if (statusCode == 426) {
          return Exception(
            'NewsAPI upgrade required. Free tier only supports recent news.',
          );
        } else if (statusCode == 429) {
          return Exception('API rate limit exceeded. Try again later.');
        }
        return Exception('Server error: ${error.response?.statusMessage}');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.unknown:
        return Exception('Network error. Please check your connection.');
      default:
        return Exception('Unexpected error occurred');
    }
  }
}
