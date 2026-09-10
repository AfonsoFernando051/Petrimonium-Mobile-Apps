import 'package:flutter/material.dart';
import 'package:petrimonium_ui/petrimonium_ui.dart';

/// Settings → Notifications: daily-mission and achievement-alert toggles.
///
/// Copy arrives as parameters — see [PrivacySection] for why.
class NotificationsSection extends StatelessWidget {
  const NotificationsSection({
    super.key,
    required this.sectionLabel,
    required this.sectionTitle,
    required this.dailyMissionRemindersLabel,
    required this.achievementAlertsLabel,
    required this.dailyMissionReminders,
    required this.achievementAlerts,
    required this.onDailyMissionRemindersChanged,
    required this.onAchievementAlertsChanged,
  });

  final Widget Function(String label) sectionLabel;
  final String sectionTitle;
  final String dailyMissionRemindersLabel;
  final String achievementAlertsLabel;
  final bool dailyMissionReminders;
  final bool achievementAlerts;
  final ValueChanged<bool> onDailyMissionRemindersChanged;
  final ValueChanged<bool> onAchievementAlertsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionLabel(sectionTitle.toUpperCase()),
        SettingsToggleCard(
          children: [
            SettingsSwitchTile(
              icon: Icons.notifications_active_outlined,
              label: dailyMissionRemindersLabel,
              value: dailyMissionReminders,
              onChanged: onDailyMissionRemindersChanged,
            ),
            SettingsSwitchTile(
              icon: Icons.emoji_events_outlined,
              label: achievementAlertsLabel,
              value: achievementAlerts,
              onChanged: onAchievementAlertsChanged,
            ),
          ],
        ),
      ],
    );
  }
}
