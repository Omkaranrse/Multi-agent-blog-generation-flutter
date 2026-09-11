class BlogHistoryEntry {
  const BlogHistoryEntry({
    required this.id,
    required this.topic,
    required this.audience,
    required this.blog,
    required this.createdAt,
  });

  final String id;
  final String topic;
  final String audience;
  final String blog;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic': topic,
        'audience': audience,
        'blog': blog,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BlogHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BlogHistoryEntry(
      id: json['id'] as String,
      topic: json['topic'] as String,
      audience: json['audience'] as String,
      blog: json['blog'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
