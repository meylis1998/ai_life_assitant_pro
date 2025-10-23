import 'package:equatable/equatable.dart';

class NewsArticle extends Equatable {
  final String title;
  final String description;
  final String source;
  final String url;
  final String? imageUrl;
  final DateTime publishedAt;
  final String? author;
  final String? content;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.source,
    required this.url,
    this.imageUrl,
    required this.publishedAt,
    this.author,
    this.content,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        source,
        url,
        imageUrl,
        publishedAt,
        author,
        content,
      ];
}
