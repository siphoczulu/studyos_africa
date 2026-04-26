import 'package:flutter_test/flutter_test.dart';
import 'package:studyos_africa/features/timetable/domain/timetable_time_parser.dart';

void main() {
  group('TimetableTimeParser.parseToMinutes', () {
    test('parses valid HH:MM values', () {
      expect(TimetableTimeParser.parseToMinutes('08:30'), 510);
      expect(TimetableTimeParser.parseToMinutes('00:00'), 0);
      expect(TimetableTimeParser.parseToMinutes('23:59'), 1439);
    });

    test('returns null for invalid formats', () {
      expect(TimetableTimeParser.parseToMinutes('8:30'), isNull);
      expect(TimetableTimeParser.parseToMinutes('24:00'), isNull);
      expect(TimetableTimeParser.parseToMinutes('12:60'), isNull);
      expect(TimetableTimeParser.parseToMinutes('12-30'), isNull);
    });
  });

  group('TimetableTimeParser.isValidFormat', () {
    test('returns true only for valid HH:MM values', () {
      expect(TimetableTimeParser.isValidFormat('08:30'), isTrue);
      expect(TimetableTimeParser.isValidFormat('00:00'), isTrue);
      expect(TimetableTimeParser.isValidFormat('23:59'), isTrue);
      expect(TimetableTimeParser.isValidFormat('8:30'), isFalse);
      expect(TimetableTimeParser.isValidFormat('24:00'), isFalse);
    });
  });

  group('TimetableTimeParser.isEndAfterStart', () {
    test('returns true when end is after start', () {
      expect(
        TimetableTimeParser.isEndAfterStart(
          startMinutes: 510,
          endMinutes: 600,
        ),
        isTrue,
      );
    });

    test('returns false when end equals start', () {
      expect(
        TimetableTimeParser.isEndAfterStart(
          startMinutes: 510,
          endMinutes: 510,
        ),
        isFalse,
      );
    });

    test('returns false when end is before start', () {
      expect(
        TimetableTimeParser.isEndAfterStart(
          startMinutes: 600,
          endMinutes: 510,
        ),
        isFalse,
      );
    });
  });
}
