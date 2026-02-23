import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';

class DateHelper {
  static DateTimeRange getCurrentWeekRange() {
    int todayWeekday = Jiffy.now().dayOfWeek;
    DateTime weekStart = DateTime.now().subtract(
      Duration(days: (todayWeekday - 1)),
    );
    weekStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
    return DateTimeRange(
      start: weekStart,
      end: weekStart.add(const Duration(days: 6)),
    );
  }

  static DateTimeRange getCurrentMonthRange() {
    DateTime now = DateTime.now();
    DateTime monthStart = DateTime(now.year, now.month, 1);
    DateTime monthEnd = DateTime(now.year, now.month + 1, 0);
    return DateTimeRange(start: monthStart, end: monthEnd);
  }
}
