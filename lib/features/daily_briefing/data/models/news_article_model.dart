import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/news_article.dart';

part 'news_article_model.g.dart';

@JsonSerializable()
class NewsArticleModel extends NewsArticle {
  const NewsArticleModel({
    required super.title,
    super.description,
    super.content,
    required super.source,
    super.author,
    required super.url,
    super.imageUrl,
    required super.publishedAt,
    super.category,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) =>
      _$NewsArticleModelFromJson(json);

  Map<String, dynamic> toJson() => _$NewsArticleModelToJson(this);

  /// Create from NewsAPI.org response
  factory NewsArticleModel.fromNewsApi(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>?;

    return NewsArticleModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      content: json['content'] as String?,
      source: source?['name'] as String? ?? 'Unknown',
      author: json['author'] as String?,
      url: json['url'] as String? ?? '',
      imageUrl: json['urlToImage'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      category: null, // Category is set by the API request, not the response
    );
  }

  NewsArticle toEntity() => NewsArticle(
        title: title,
        description: description,
        content: content,
        source: source,
        author: author,
        url: url,
        imageUrl: imageUrl,
        publishedAt: publishedAt,
        category: category,
      );

  /// Create model from entity
  factory NewsArticleModel.fromEntity(NewsArticle entity) {
    return NewsArticleModel(
      title: entity.title,
      description: entity.description,
      content: entity.content,
      source: entity.source,
      author: entity.author,
      url: entity.url,
      imageUrl: entity.imageUrl,
      publishedAt: entity.publishedAt,
      category: entity.category,
    );
  }

  /// Create model with category
  NewsArticleModel copyWith({
    String? title,
    String? description,
    String? content,
    String? source,
    String? author,
    String? url,
    String? imageUrl,
    DateTime? publishedAt,
    String? category,
  }) {
    return NewsArticleModel(
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      source: source ?? this.source,
      author: author ?? this.author,
      url: url ?? this.url,
      imageUrl: imageUrl ?? this.imageUrl,
      publishedAt: publishedAt ?? this.publishedAt,
      category: category ?? this.category,
    );
  }
}
