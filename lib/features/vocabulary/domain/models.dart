// Vocabulary domain models (contract §4.7).

class VocabSet {
  const VocabSet({
    required this.id,
    required this.slug,
    required this.title,
    required this.cefrLevel,
    required this.category,
    required this.isPremium,
    required this.isLocked,
    this.wordCount = 0,
  });

  final String id;
  final String slug;
  final String title;
  final String cefrLevel;
  final String category;
  final bool isPremium;
  final bool isLocked;
  final int wordCount;

  factory VocabSet.fromJson(Map<String, dynamic> json) => VocabSet(
    id: json['id'] as String,
    slug: json['slug'] as String,
    title: json['title'] as String,
    cefrLevel: json['cefr_level'] as String? ?? '',
    category: json['category'] as String? ?? 'general',
    isPremium: json['is_premium'] as bool? ?? false,
    isLocked: json['is_locked'] as bool? ?? false,
    wordCount: (json['word_count'] as num?)?.toInt() ?? 0,
  );
}

class VocabItem {
  const VocabItem({
    required this.id,
    required this.word,
    required this.translationUz,
    required this.definitionEn,
    required this.example,
  });

  final String id;
  final String word;
  final String translationUz;
  final String definitionEn;
  final String example;

  factory VocabItem.fromJson(Map<String, dynamic> json) => VocabItem(
    id: json['id'] as String,
    word: json['word'] as String,
    translationUz: json['translation_uz'] as String? ?? '',
    definitionEn: json['definition_en'] as String? ?? '',
    example: json['example'] as String? ?? '',
  );
}

class VocabSetDetail {
  const VocabSetDetail({required this.set, required this.items});
  final VocabSet set;
  final List<VocabItem> items;
}
