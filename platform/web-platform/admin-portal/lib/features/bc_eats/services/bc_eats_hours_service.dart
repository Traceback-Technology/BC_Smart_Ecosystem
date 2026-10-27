class BcEatsOperatingStatus {
  final bool isOpen;
  final String label;
  final String detail;

  const BcEatsOperatingStatus({
    required this.isOpen,
    required this.label,
    required this.detail,
  });
}

class BcEatsHoursService {
  const BcEatsHoursService();

  /// Returns the tuck-shop opening window for a given day.
  ///
  /// Monday-Thursday: 08:30-16:30
  /// Friday:          08:30-16:00
  /// Saturday:        10:00-14:00
  /// Sunday:          Closed
  ///
  /// Public-holiday detection can later be supplied by the backend
  /// or a central campus calendar.
  ({DateTime opens, DateTime closes})? _openingWindow(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return (
          opens: DateTime(date.year, date.month, date.day, 8, 30),
          closes: DateTime(date.year, date.month, date.day, 16, 30),
        );

      case DateTime.friday:
        return (
          opens: DateTime(date.year, date.month, date.day, 8, 30),
          closes: DateTime(date.year, date.month, date.day, 16),
        );

      case DateTime.saturday:
        return (
          opens: DateTime(date.year, date.month, date.day, 10),
          closes: DateTime(date.year, date.month, date.day, 14),
        );

      case DateTime.sunday:
        return null;
    }

    return null;
  }

  BcEatsOperatingStatus statusAt(DateTime now) {
    final todayWindow = _openingWindow(now);

    if (todayWindow != null) {
      final isOpen =
          !now.isBefore(todayWindow.opens) && now.isBefore(todayWindow.closes);

      if (isOpen) {
        return BcEatsOperatingStatus(
          isOpen: true,
          label: 'Open now',
          detail: 'Closes ${_formatTime(todayWindow.closes)}',
        );
      }
    }

    final nextOpening = _findNextOpening(now);

    if (nextOpening == null) {
      return const BcEatsOperatingStatus(
        isOpen: false,
        label: 'Closed now',
        detail: 'Opening hours unavailable',
      );
    }

    return BcEatsOperatingStatus(
      isOpen: false,
      label: 'Closed now',
      detail: _nextOpeningLabel(now, nextOpening),
    );
  }

  DateTime? _findNextOpening(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    for (var dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final window = _openingWindow(date);

      if (window == null) {
        continue;
      }

      if (dayOffset == 0) {
        if (now.isBefore(window.opens)) {
          return window.opens;
        }

        continue;
      }

      return window.opens;
    }

    return null;
  }

  String _nextOpeningLabel(DateTime now, DateTime opening) {
    final today = DateTime(now.year, now.month, now.day);
    final openingDay = DateTime(opening.year, opening.month, opening.day);

    final dayDifference = openingDay.difference(today).inDays;
    final time = _formatTime(opening);

    if (dayDifference == 0) {
      return 'Opens at $time';
    }

    if (dayDifference == 1) {
      return 'Opens tomorrow at $time';
    }

    return 'Opens ${_weekdayName(opening.weekday)} at $time';
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
    }

    return '';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}
