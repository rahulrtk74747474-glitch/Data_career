import 'package:dataquest_analyst_career/services/company_next_day_simulation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('company outcomes are deterministic and bounded, with trade-offs', () {
    for (final key in const [
      'ecommerce', 'saas', 'bank', 'hospital', 'logistics',
    ]) {
      final baseline = CompanyNextDaySimulation.evaluate(key, 'validate');
      final scaled = CompanyNextDaySimulation.evaluate(key, 'scale');
      final cut = CompanyNextDaySimulation.evaluate(key, 'cut');
      expect(baseline.toJson(),
          CompanyNextDaySimulation.evaluate(key, 'validate').toJson());
      for (final result in [baseline, scaled, cut]) {
        expect(result.service, inInclusiveRange(0, 100));
        expect(result.cost, inInclusiveRange(0, 100));
        expect(result.risk, inInclusiveRange(0, 100));
        expect(result.budget, greaterThanOrEqualTo(0));
        expect(result.explanation, contains('scenario assumptions'));
      }
      expect(scaled.service, greaterThan(baseline.service));
      expect(scaled.budget, lessThan(baseline.budget));
      expect(cut.risk, greaterThan(baseline.risk));
      expect(cut.cost, lessThan(baseline.cost));
    }
  });

  test('next-day intervention survives reopening and does not affect others',
      () async {
    const repository = CompanyNextDayRepository();
    final result = CompanyNextDaySimulation.evaluate('hospital', 'validate');
    await repository.save(result);
    final restored = await repository.load('hospital');
    expect(restored?.toJson(), result.toJson());
    expect(await repository.load('bank'), isNull);
    await repository.save(CompanyNextDaySimulation.evaluate('bank', 'cut'));
    expect((await repository.loadAll()).keys, containsAll(['hospital', 'bank']));
  });

  test('unknown intervention is not accepted', () {
    expect(() => CompanyNextDaySimulation.evaluate('bank', 'invisible'),
        throwsArgumentError);
    expect(() => CompanyNextDaySimulation.evaluate('unknown', 'scale'),
        throwsArgumentError);
  });
}
