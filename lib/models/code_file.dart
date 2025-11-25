/// Model class for a single code file
class CodeFile {
  final String fileName; // e.g., "main.cpp", "test.py"
  String content;

  CodeFile({
    required this.fileName,
    required this.content,
  });

  /// Get file extension
  String get extension {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last : '';
  }

  /// Get file name without extension
  String get nameWithoutExtension {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.sublist(0, parts.length - 1).join('.');
    }
    return fileName;
  }

  /// Create from JSON
  factory CodeFile.fromJson(Map<String, dynamic> json) {
    return CodeFile(
      fileName: json['fileName'] as String,
      content: json['content'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'content': content,
    };
  }

  /// Copy with new content
  CodeFile copyWith({String? fileName, String? content}) {
    return CodeFile(
      fileName: fileName ?? this.fileName,
      content: content ?? this.content,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CodeFile &&
        other.fileName == fileName &&
        other.content == content;
  }

  @override
  int get hashCode => fileName.hashCode ^ content.hashCode;

  @override
  String toString() => 'CodeFile(fileName: $fileName, contentLength: ${content.length})';
}
