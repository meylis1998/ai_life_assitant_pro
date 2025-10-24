import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/repositories/news_repository.dart';
import '../datasources/news_api_datasource.dart';

class NewsRepositoryImpl implements NewsRepository {
  final NewsApiDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  NewsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<NewsArticle>>> getTopHeadlines({
    String? country,
    String? category,
    int pageSize = 10,
  }) async {
    // Check network connectivity
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final articles = await remoteDataSource.getTopHeadlines(
        country: country,
        category: category,
        pageSize: pageSize,
      );

      return Right(articles.map((model) => model.toEntity()).toList());
    } on Exception catch (e) {
      return Left(NewsFailure(message: e.toString()));
    } catch (e) {
      return Left(NewsFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<NewsArticle>>> searchNews({
    required String query,
    int pageSize = 10,
  }) async {
    // Check network connectivity
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final articles = await remoteDataSource.searchNews(
        query: query,
        pageSize: pageSize,
      );

      return Right(articles.map((model) => model.toEntity()).toList());
    } on Exception catch (e) {
      return Left(NewsFailure(message: e.toString()));
    } catch (e) {
      return Left(NewsFailure(message: 'Unexpected error: $e'));
    }
  }
}
