import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/news_article.dart';

/// Abstract repository interface for news data
abstract class NewsRepository {
  /// Get top news headlines
  ///
  /// Parameters:
  /// - [country]: Country code (e.g., 'us', 'gb')
  /// - [category]: News category (e.g., 'business', 'technology', 'sports')
  /// - [pageSize]: Number of articles to fetch (default: 10)
  ///
  /// Returns:
  /// - Right(List<NewsArticle>) on success
  /// - Left(Failure) on error
  Future<Either<Failure, List<NewsArticle>>> getTopHeadlines({
    String? country,
    String? category,
    int pageSize = 10,
  });

  /// Search news by keywords
  ///
  /// Parameters:
  /// - [query]: Search keywords
  /// - [pageSize]: Number of articles to fetch (default: 10)
  ///
  /// Returns:
  /// - Right(List<NewsArticle>) on success
  /// - Left(Failure) on error
  Future<Either<Failure, List<NewsArticle>>> searchNews({
    required String query,
    int pageSize = 10,
  });
}
