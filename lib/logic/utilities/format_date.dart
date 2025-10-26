import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('dd-MM-yyyy').format(date);
}

DateTime parseToDateTime(dynamic value) {
  if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
  // fallback for unexpected types
  try {
    return DateTime.fromMillisecondsSinceEpoch(value as int);
  } catch (_) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

Timestamp parseToTimestamp(DateTime date) {
  return Timestamp.fromDate(date);
}

