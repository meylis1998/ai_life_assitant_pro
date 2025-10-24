// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_article_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsArticleModel _$NewsArticleModelFromJson(Map<String, dynamic> json) =>
    NewsArticleModel(
      title: json['title'] as String,
      description: json['description'] as String?,
      content: json['content'] as String?,
      source: json['source'] as String,
      author: json['author'] as String?,
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String?,
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      category: json['category'] as String?,
    );

Map<String, dynamic> _$NewsArticleModelToJson(NewsArticleModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'description': instance.description,
      'content': instance.content,
      'source': instance.source,
      'author': instance.author,
      'url': instance.url,
      'imageUrl': instance.imageUrl,
      'publishedAt': instance.publishedAt.toIso8601String(),
      'category': instance.category,
    };
