import '../../../core/api/api_client.dart';
import '../domain/models.dart';

/// Reads and writes the course path.
///
/// Thin on purpose. Every rule that matters — what is unlocked, what a lesson
/// contains, whether an answer is right — lives on the server, so this file has
/// nothing to decide and no logic to get wrong.
class CourseRepository {
  CourseRepository(this._api);

  final ApiClient _api;

  Future<List<CourseLevel>> path() async {
    final data = await _api.get('/learn/path');
    return ((data['courses'] as List?) ?? const [])
        .map((c) => CourseLevel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<UnitDetail> unit(String unitId) async =>
      UnitDetail.fromJson(await _api.get('/learn/unit/$unitId'));

  Future<List<Drill>> startLesson(String lessonId) async {
    final data = await _api.post('/learn/lesson/$lessonId/start');
    return ((data['items'] as List?) ?? const [])
        .map((i) => Drill.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<LessonResult> submitLesson(
    String lessonId,
    Map<String, dynamic> answers, {
    bool partial = false,
  }) async => LessonResult.fromJson(
    await _api.post(
      '/learn/lesson/$lessonId/submit',
      body: {'answers': answers, 'partial': partial},
    ),
  );



  Future<List<Drill>> testOut(String unitId) async {
    final data = await _api.get('/learn/unit/$unitId/test-out');
    return ((data['items'] as List?) ?? const [])
        .map((i) => Drill.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<TestOutResult> submitTestOut(
    String unitId,
    Map<String, dynamic> answers,
  ) async => TestOutResult.fromJson(
    await _api.post('/learn/unit/$unitId/test-out', body: {'answers': answers}),
  );
}
