import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/news_article_model.dart';

abstract class NewsApiDataSource {
  Future<List<NewsArticleModel>> getTopHeadlines({
    String? category,
    String? country,
    int limit = 10,
  });
}

class NewsApiDataSourceImpl implements NewsApiDataSource {
  final http.Client client;
  static const String _baseUrl = 'https://newsapi.org/v2';

  NewsApiDataSourceImpl({required this.client});

  String get _apiKey => dotenv.env['NEWS_API_KEY'] ?? '';

  @override
  Future<List<NewsArticleModel>> getTopHeadlines({
    String? category,
    String? country = 'us',
    int limit = 10,
  }) async {
    var url = '$_baseUrl/top-headlines?country=$country&pageSize=$limit&apiKey=$_apiKey';

    if (category != null && category.isNotEmpty) {
      url += '&category=$category';
    }

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> articles = data['articles'];

      return articles
          .map((article) => NewsArticleModel.fromJson(article))
          .where((article) => article.title.isNotEmpty)
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Invalid News API key');
    } else if (response.statusCode == 429) {
      throw Exception('News API rate limit exceeded');
    } else {
      throw Exception('Failed to load news: ${response.statusCode}');
    }
  }
}
