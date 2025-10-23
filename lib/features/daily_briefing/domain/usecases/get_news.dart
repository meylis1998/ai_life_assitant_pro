import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/news_article.dart';
import '../repositories/briefing_repository.dart';

class GetNews implements UseCase<List<NewsArticle>, GetNewsParams> {
  final BriefingRepository repository;

  GetNews(this.repository);

  @override
  Future<Either<Failure, List<NewsArticle>>> call(GetNewsParams params) async {
    return await repository.getTopNews(
      category: params.category,
      country: params.country,
      limit: params.limit,
    );
  }
}

class GetNewsParams extends Equatable {
  final String? category;
  final String? country;
  final int limit;

  const GetNewsParams({
    this.category,
    this.country = 'us',
    this.limit = 10,
  });

  @override
  List<Object?> get props => [category, country, limit];
}
