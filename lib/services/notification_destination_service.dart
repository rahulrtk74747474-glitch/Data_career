enum NotificationDestination {
  dailyChallenge,
  reviewQueue,
}

class NotificationDestinationService {
  const NotificationDestinationService._();

  static NotificationDestination? resolve(String? payload) {
    switch (payload) {
      case 'daily_challenge':
        return NotificationDestination.dailyChallenge;
      case 'review_queue':
        return NotificationDestination.reviewQueue;
      default:
        return null;
    }
  }
}
