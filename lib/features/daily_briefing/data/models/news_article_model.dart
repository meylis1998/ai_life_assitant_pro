import '../../domain/entities/news_article.dart';

class NewsArticleModel extends NewsArticle {
  const NewsArticleModel({
    required super.title,
    required super.description,
    required super.source,
    required super.url,
    super.imageUrl,
    required super.publishedAt,
    super.author,
    super.content,
  });

  factory NewsArticleModel.fromJson(Map<String, dynamic> json) {
    return NewsArticleModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      source: json['source']['name'] as String? ?? 'Unknown',
      url: json['url'] as String? ?? '',
      imageUrl: json['urlToImage'] as String?,
      publishedAt: json['publishedAt'] != null
          ? DateTime.parse(json['publishedAt'] as String)
          : DateTime.now(),
      author: json['author'] as String?,
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'source': {'name': source},
      'url': url,
      'urlToImage': imageUrl,
      'publishedAt': publishedAt.toIso8601String(),
      'author': author,
      'content': content,
    };
  }
}
