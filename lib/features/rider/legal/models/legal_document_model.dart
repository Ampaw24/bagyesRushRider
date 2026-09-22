import 'package:equatable/equatable.dart';

/// A server-managed legal document — currently `GET /rider-agreement`.
/// `body` is Markdown, not HTML, so callers render it via `markdownToHtml`
/// into the existing `flutter_html` pipeline rather than a raw string.
class LegalDocumentModel extends Equatable {
  final int? id;
  final String? version;
  final String title;
  final String body;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? publishedAt;

  const LegalDocumentModel({
    this.id,
    this.version,
    required this.title,
    required this.body,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.publishedAt,
  });

  factory LegalDocumentModel.fromJson(Map<String, dynamic> json) {
    return LegalDocumentModel(
      id: json['id'] as int?,
      version: json['version'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      publishedAt: json['published_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, version, title, body, fileUrl];
}
