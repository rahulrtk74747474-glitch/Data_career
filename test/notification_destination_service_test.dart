import 'package:dataquest_analyst_career/services/notification_destination_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('daily challenge payload resolves correctly', () {
    expect(
      NotificationDestinationService.resolve('daily_challenge'),
      NotificationDestination.dailyChallenge,
    );
  });

  test('review queue payload resolves correctly', () {
    expect(
      NotificationDestinationService.resolve('review_queue'),
      NotificationDestination.reviewQueue,
    );
  });

  test('unknown notification payload is ignored safely', () {
    expect(NotificationDestinationService.resolve('unknown'), isNull);
    expect(NotificationDestinationService.resolve(null), isNull);
  });
}
