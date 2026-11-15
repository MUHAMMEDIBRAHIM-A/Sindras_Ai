/// Document metadata model.
class DocumentModel {
  final String id;
  final String filename;
  final String contentType;
  final int totalPages;
  final String uploadedAt;

  DocumentModel({
    required this.id,
    required this.filename,
    required this.contentType,
    required this.totalPages,
    required this.uploadedAt,
  });

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'],
      filename: json['filename'],
      contentType: json['content_type'],
      totalPages: json['total_pages'],
      uploadedAt: json['uploaded_at'],
    );
  }

  /// Human-readable file type label.
  String get typeLabel {
    switch (contentType) {
      case 'application/pdf':
        return 'PDF';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'DOCX';
      case 'text/plain':
        return 'TXT';
      default:
        return 'FILE';
    }
  }
}
