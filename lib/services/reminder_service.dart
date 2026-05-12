import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prescription_models.dart';

class ReminderService {
  static ReminderService? _instance;
  static ReminderService get instance => _instance ??= ReminderService._();
  ReminderService._();

  static const String _kRemindersKey = 'prescription_reminders_v1';

  Future<List<PrescriptionReminder>> getAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kRemindersKey) ?? const [];
    return raw
        .map((e) {
          try {
            final map = jsonDecode(e) as Map<String, dynamic>;
            return PrescriptionReminder.fromJson(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<PrescriptionReminder>()
        .toList();
  }

  Future<void> saveReminder(PrescriptionReminder reminder) async {
    final reminders = await getAllReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      reminders[index] = reminder;
    } else {
      reminders.add(reminder);
    }
    await _persist(reminders);
  }

  Future<void> removeReminder(String reminderId) async {
    final reminders = await getAllReminders();
    reminders.removeWhere((r) => r.id == reminderId);
    await _persist(reminders);
  }

  Future<void> _persist(List<PrescriptionReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = reminders.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_kRemindersKey, raw);
  }
}
