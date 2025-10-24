import 'package:equatable/equatable.dart';

/// Represents a news article from the news API
class NewsArticle extends Equatable {
  final String title;
  final String? description;
  final String? content;
  final String source;
  final String? author;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String? category;

  const NewsArticle({
    required this.title,
    this.description,
    this.content,
    required this.source,
    this.author,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    this.category,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        content,
        source,
        author,
        url,
        imageUrl,
        publishedAt,
        category,
      ];
}
