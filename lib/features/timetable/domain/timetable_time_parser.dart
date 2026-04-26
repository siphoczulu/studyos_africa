class TimetableTimeParser {
  static final RegExp _timePattern = RegExp(
    r'^([01]\d|2[0-3]):([0-5]\d)$',
  );

  static int? parseToMinutes(String value) {
    final match = _timePattern.firstMatch(value.trim());
    if (match == null) {
      return null;
    }

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    return (hours * 60) + minutes;
  }

  static bool isValidFormat(String value) {
    return parseToMinutes(value) != null;
  }

  static bool isEndAfterStart({
    required int startMinutes,
    required int endMinutes,
  }) {
    return endMinutes > startMinutes;
  }
}
