# Streakly

A polished, fully offline habit tracker for Android. Build a streak, one day
at a time.

## What it does

- **Create habits** — name, icon (28 options), colour (12 options), a streak
  target (7–365 days) and an optional daily reminder time.
- **Daily check-ins** — tap the circle on a habit card, or tap any day on
  the week strip to check in (or undo) past days.
- **Streaks** — current and best streaks with a flame badge that heats up
  as the streak grows.
- **Calendar heatmap** — a GitHub-style heatmap of the last 16 weeks, plus
  a full month calendar per habit where any day can be toggled.
- **Weekly / monthly stats** — 7-day and 30-day completion rates, per-habit
  and overall stats screens.
- **Habit notes** — free-text notes attached to a day, shown as a timeline
  on the habit detail screen.
- **Edit / archive / delete** — archive a habit to pause it (reminders stop
  too), restore it later, or delete it for good.
- **Local reminders** — one daily notification per habit at the time you
  pick, using the device time zone. No server involved.
- **Light & dark themes** — follows the system theme (Material 3).

## Privacy

Everything lives on the device in a local SQLite database. There is no
account, no network access, no analytics and no tracking. The app starts
empty — no demo or sample habits.

## Tech

- Flutter 3.50, Dart 3.14, Material 3 (`material_ui`)
- `sqflite` for local storage (habits, check-ins, notes)
- `flutter_local_notifications` 22.3.3 + `flutter_timezone` for reminders
- `permission_handler` 12.x for the notification permission

## Build

```sh
export PATH=~/workspace/flutter-sdk/flutter/bin:$PATH
export ANDROID_HOME=~/workspace/android-sdk
export JAVA_HOME=~/workspace/android-sdk/jdk17
export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"
export GRADLE_OPTS="-Djava.net.preferIPv4Stack=true"
export GRADLE_USER_HOME=~/workspace/overnight-8-apps/.gradle-home
export TMPDIR=~/workspace/overnight-5-apps/.tmp
export CI=true

flutter analyze
flutter test
flutter build apk --release
```

The release APK is signed with the debug key by default (see
`android/app/build.gradle.kts`); use a real release keystore for the
Play Store upload.

## Project layout

```
lib/
  main.dart                  App shell: 4-tab navigation (Today / Calendar / Stats / Settings)
  models/                    Habit, CheckIn, HabitNote, HabitStats
  services/                  DatabaseHelper, HabitRepository, StreakCalculator, NotificationService
  screens/                   Home, Habit detail, Add/Edit, Calendar, Stats, Settings, Archive
  widgets/                   HabitCard, WeekStrip, Heatmap, StreakBadge, pickers, …
  utils/                     date helpers, icon/colour options, reminder-time maths
  theme/                     Material 3 light/dark themes
test/
  streak_calculator_test.dart  streak / completion / week / month math
  date_utils_test.dart         date keys, week starts, month lengths
  reminder_time_test.dart      next fire time, 12h/24h formatting
  habit_model_test.dart        model round-trips
  database_test.dart           SQLite CRUD (sqflite_common_ffi)
  repository_test.dart         create / toggle / stats / archive / notes
  widget_test.dart             home empty state, card, badge, add form, app shell
```

## License

Private project — not open for reuse.
