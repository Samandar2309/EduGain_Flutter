// Placement test models (contract §4.9 / §4.2). Questions never include the
// correct answer — grading is server-side (REQ-19-006).

class PlacementQuestion {
  const PlacementQuestion({
    required this.id,
    required this.section,
    required this.cefrLevel,
    required this.type,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String section;
  final String cefrLevel;
  final String type; // mcq | fill_blank
  final String prompt;
  final List<String> options;

  bool get isMcq => type == 'mcq';

  factory PlacementQuestion.fromJson(Map<String, dynamic> json) =>
      PlacementQuestion(
        id: json['id'] as String,
        section: json['section'] as String? ?? '',
        cefrLevel: json['cefr_level'] as String? ?? '',
        type: json['type'] as String? ?? 'mcq',
        prompt: json['prompt'] as String? ?? '',
        options: ((json['options'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

class PlacementResult {
  const PlacementResult({required this.resultCefr, required this.breakdown});

  final String? resultCefr;
  final Map<String, dynamic> breakdown;

  factory PlacementResult.fromJson(Map<String, dynamic> json) => PlacementResult(
    resultCefr: json['result_cefr'] as String?,
    breakdown: Map<String, dynamic>.from(
      (json['breakdown'] as Map?) ?? const {},
    ),
  );
}
