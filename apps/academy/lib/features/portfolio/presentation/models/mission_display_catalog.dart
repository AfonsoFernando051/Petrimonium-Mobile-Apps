import 'package:petrimonium_academy/core/utils/translator.dart';
import 'package:petrimonium_academy/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

/// Display-only copy/icon for each mission code — the backend
/// (`AchievementController`'s sibling `MissionController`,
/// `GET /api/v1/missions`) is authoritative for which missions exist,
/// their progress, target, and XP reward; this only maps a known code to
/// what the card shows. A code with no entry here still renders (title
/// falls back to the raw code) rather than disappearing, so a backend-side
/// catalog change never silently hides a real mission.
class MissionDisplayInfo {
  final String title;
  final String description;
  final IconData icon;

  const MissionDisplayInfo({required this.title, required this.description, required this.icon});
}

class MissionDisplayCatalog {
  const MissionDisplayCatalog._();

  static Map<String, MissionDisplayInfo> get _entries => {
    'daily_complete_lesson': MissionDisplayInfo(
      title: Translator.translate(AppStrings.missionDailyLessonTitle),
      description: Translator.translate(AppStrings.missionDailyLessonDescription),
      icon: Icons.menu_book,
    ),
    'daily_complete_two_lessons': MissionDisplayInfo(
      title: Translator.translate(AppStrings.missionDailyTwoTitle),
      description: Translator.translate(AppStrings.missionDailyTwoDescription),
      icon: Icons.local_fire_department,
    ),
    'weekly_complete_three_lessons': MissionDisplayInfo(
      title: Translator.translate(AppStrings.missionWeeklyThreeTitle),
      description: Translator.translate(AppStrings.missionWeeklyThreeDescription),
      icon: Icons.calendar_view_week,
    ),
    'weekly_complete_module': MissionDisplayInfo(
      title: Translator.translate(AppStrings.missionWeeklyModuleTitle),
      description: Translator.translate(AppStrings.missionWeeklyModuleDescription),
      icon: Icons.workspace_premium,
    ),
  };

  static MissionDisplayInfo forCode(String code) {
    return _entries[code] ?? MissionDisplayInfo(title: code, description: '', icon: Icons.flag_outlined);
  }
}
