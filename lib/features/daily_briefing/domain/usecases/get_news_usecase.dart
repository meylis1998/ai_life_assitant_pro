import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/news_article.dart';
import '../repositories/news_repository.dart';

/// Parameters for getting news
class GetNewsParams {
  final String? country;
  final String? category;
  final String? searchQuery;
  final int pageSize;

  const GetNewsParams({
    this.country,
    this.category,
    this.searchQuery,
    this.pageSize = 10,
  });
}

/// Use case for getting news articles
class GetNewsUseCase implements UseCase<List<NewsArticle>, GetNewsParams> {
  final NewsRepository repository;

  GetNewsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NewsArticle>>> call(GetNewsParams params) async {
    // If search query is provided, use search endpoint
    if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
      return await repository.searchNews(
        query: params.searchQuery!,
        pageSize: params.pageSize,
      );
    }

    // Otherwise, get top headlines
    return await repository.getTopHeadlines(
      country: params.country,
      category: params.category,
      pageSize: params.pageSize,
    );
  }
}
