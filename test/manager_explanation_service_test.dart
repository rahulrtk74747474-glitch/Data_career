import 'package:dataquest_analyst_career/services/manager_explanation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decision-ready manager explanation scores above weak statement', () {
    final strong = ManagerExplanationService.score(
      text:
          'Enterprise revenue is 8000 versus 3100 Consumer in this snapshot. '
          'That does not prove the segment causes better profit because margin and refund mix may differ. '
          'I recommend comparing gross margin and refund rate by segment and monitoring contribution margin next.',
      evidenceTerms: const ['8000', '3100', 'enterprise', 'revenue'],
      impactTerms: const ['profit', 'margin', 'refund'],
      uncertaintyTerms: const ['does not prove', 'may', 'mix'],
      recommendationTerms: const ['recommend', 'comparing', 'monitoring'],
    );
    final weak = ManagerExplanationService.score(
      text: 'Enterprise is best. Do more of it.',
      evidenceTerms: const ['8000', '3100', 'enterprise', 'revenue'],
      impactTerms: const ['profit', 'margin', 'refund'],
      uncertaintyTerms: const ['does not prove', 'may', 'mix'],
      recommendationTerms: const ['recommend', 'compare', 'monitor'],
    );

    expect(strong.total, greaterThanOrEqualTo(75));
    expect(strong.total, greaterThan(weak.total));
    expect(strong.uncertainty, 15);
  });
}
