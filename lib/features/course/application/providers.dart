import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/course_repository.dart';
import '../domain/models.dart';

final courseRepositoryProvider = Provider<CourseRepository>(
  (ref) => CourseRepository(ref.read(apiClientProvider)),
);

/// The whole path.
///
/// Not kept alive: finishing a lesson changes which node is current, and a
/// cached path would show a learner the state they were in before they did the
/// work. Invalidated explicitly after every submit.
final coursePathProvider = FutureProvider<List<CourseLevel>>(
  (ref) => ref.read(courseRepositoryProvider).path(),
);

final unitDetailProvider = FutureProvider.family<UnitDetail, String>(
  (ref, unitId) => ref.read(courseRepositoryProvider).unit(unitId),
);

final lessonDrillsProvider = FutureProvider.family<List<Drill>, String>(
  (ref, lessonId) => ref.read(courseRepositoryProvider).startLesson(lessonId),
);



final testOutDrillsProvider = FutureProvider.family<List<Drill>, String>(
  (ref, unitId) => ref.read(courseRepositoryProvider).testOut(unitId),
);
