import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_verb_master/services/stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stats service returns empty maps for malformed stored data', () async {
    SharedPreferences.setMockInitialValues({
      'practice_time': '{bad json',
      'verbs_practiced': '123',
      'verb_stats': '[1,2,3]',
    });

    final service = await StatsService.create();

    expect(await service.getPracticeTimes(), isEmpty);
    expect(await service.getPracticedVerbs(), isEmpty);
    expect(await service.getStats(), isEmpty);
  });
}
