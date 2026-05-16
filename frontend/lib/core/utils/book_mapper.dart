int coverColorFromId(String id) {
  const palette = [
    0xFF6C63FF,
    0xFF4B44CC,
    0xFF22C55E,
    0xFFF59E0B,
    0xFFEF4444,
    0xFF1E1E2E,
  ];
  if (id.isEmpty) return palette.first;
  return palette[id.hashCode.abs() % palette.length];
}

Map<String, Object?> bookFromApi(Map<String, dynamic> json) {
  final id = (json['id'] as String?) ?? '';
  return {
    'id': id,
    'title': json['title'] as String? ?? '',
    'totalPages': json['total_pages'] as int? ?? 0,
    'currentPage': json['current_page'] as int? ?? 0,
    'status': json['status'] as String? ?? 'reading',
    'coverColor': coverColorFromId(id),
    'coverUrl': json['cover_url'] as String?,
    'isbn': json['isbn'] as String?,
  };
}
