// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'SuperNote';

  @override
  String get settings => 'Settings';

  @override
  String get today => 'Today';

  @override
  String get noTask => 'No tasks';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get sectionCustomBg => 'Custom Background';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get sectionAccount => 'Account';

  @override
  String get sectionGemini => 'Gemini AI';

  @override
  String get sectionStorage => 'Storage';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get sectionTest => 'Test';

  @override
  String get sectionInfo => 'About';

  @override
  String get sectionFeatures => 'Features';

  @override
  String get statsSubtitle => 'View task statistics and charts';

  @override
  String get notifSound => 'Notification Sound';

  @override
  String get notifSoundDesc => 'Play sound when reminders fire';

  @override
  String get notifVibration => 'Vibrate on Notification';

  @override
  String get notifVibrationDesc => 'Vibrate device on new notifications';

  @override
  String get defaultPreReminder => 'Default Pre-Reminder';

  @override
  String get quietHours => 'Quiet Hours';

  @override
  String get quietHoursDesc =>
      'Notifications will be paused during this period';

  @override
  String get timeStart => 'Start';

  @override
  String get timeEnd => 'End';

  @override
  String get detailedBackground => 'Detailed Background';

  @override
  String get detailedBackgroundDesc =>
      'Toggle orbs and background animation effects';

  @override
  String get attachmentFile => 'File';

  @override
  String attachmentCount(Object count) {
    return '$count attachments';
  }

  @override
  String get attachFile => 'Attach file';

  @override
  String get chooseFromDevice => 'Choose from device';

  @override
  String filesAttached(Object count) {
    return '$count files attached';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get accountNotLoggedIn => 'Not logged in';

  @override
  String get accountNotLoggedInDesc => 'Open login screen';

  @override
  String get accountGuest => 'Guest';

  @override
  String get accountNoSync => 'No sync';

  @override
  String get logout => 'Log out';

  @override
  String get logoutDesc => 'Sign out of current account';

  @override
  String get login => 'Log in';

  @override
  String get loginDesc => 'Sign in to sync data';

  @override
  String get loading => 'Loading...';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get geminiLabel => 'Gemini AI';

  @override
  String get geminiConfigured => 'Configured — AI features enabled';

  @override
  String get geminiNotConfigured => 'Enter API key to enable AI';

  @override
  String get geminiEnterKey => 'Enter Gemini API Key';

  @override
  String get geminiSave => 'Save';

  @override
  String get storageLabel => 'Storage';

  @override
  String get pastTasks => 'Past Tasks';

  @override
  String get pastTasksDesc => 'Review completed tasks and stats';

  @override
  String get customBgActiveVideo => 'Video background active';

  @override
  String get customBgActiveImage => 'Image background active';

  @override
  String get customBgChoose => 'Choose image/video background';

  @override
  String get customBgDesc => 'JPG, PNG, MP4, MOV (max 50 MB)';

  @override
  String get customBgTapToChange => 'Tap to change';

  @override
  String get customBgRemove => 'Remove custom background';

  @override
  String get customBgRemoveDesc => 'Revert to default (Neon Orbs)';

  @override
  String get customBgUpdated => 'Custom background updated!';

  @override
  String get customBgRemoved => 'Custom background removed';

  @override
  String get testNotif => 'Send test notification';

  @override
  String get testNotifDesc => 'Check if notifications work';

  @override
  String get testGemini => 'Test Gemini API';

  @override
  String get addTask => 'Add task';

  @override
  String get addTaskDesc => 'Quick add task';

  @override
  String get addTaskQuick => 'Quick add task...';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get snooze => 'Snooze';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get pending => 'Pending';

  @override
  String get snoozed => 'Snoozed';

  @override
  String get morning => 'Morning';

  @override
  String get afternoon => 'Afternoon';

  @override
  String get evening => 'Evening';

  @override
  String get allDay => 'All day';

  @override
  String get taskCount => 'tasks';

  @override
  String get taskCountLabel => 'tasks';

  @override
  String get timelineToday => 'Today';

  @override
  String get timelineThisWeek => 'This week';

  @override
  String get timelineUpcoming => 'Upcoming';

  @override
  String get timelinePast => 'Past';

  @override
  String get noSchedule => 'No schedule';

  @override
  String get noScheduleDesc => 'No tasks scheduled yet';

  @override
  String get quickTask => 'Quick add task';

  @override
  String get taskToday => 'tasks today';

  @override
  String get progressLabel => 'Today\'s progress';

  @override
  String get progressDetail => 'tasks completed';

  @override
  String get appVersion => 'SuperNote';

  @override
  String appVersionDesc(Object version) {
    return 'v$version — Smart reminder app for students';
  }

  @override
  String get deleteTaskTitle => 'Delete task';

  @override
  String deleteTaskConfirm(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterClass => 'Class';

  @override
  String get filterExam => 'Exam';

  @override
  String get filterAssignment => 'Assignment';

  @override
  String get filterPersonal => 'Personal';

  @override
  String get overdue => 'Overdue';

  @override
  String get thisWeek => 'This week';

  @override
  String get later => 'Later';

  @override
  String get noDate => 'No date';

  @override
  String get emptyRelax => 'Relaxing day — no tasks yet!';

  @override
  String get emptyRelaxDesc => 'Enjoy your day, tasks will come later.';

  @override
  String get emptyDone => 'All done, time to rest!';

  @override
  String get emptyFree => 'An empty day — add a new task.';

  @override
  String get emptyHint => 'Type a task above';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get timelineTitle => 'Timeline';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Tu';

  @override
  String get weekdayWed => 'We';

  @override
  String get weekdayThu => 'Th';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'Su';

  @override
  String get todayButton => 'Today';

  @override
  String get upcomingTasks => 'Upcoming Tasks';

  @override
  String get noUpcoming => 'No upcoming tasks';

  @override
  String get addTaskForDay => 'Add task for this day';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String daysLeft(Object days) {
    return '$days days left';
  }

  @override
  String get monday => 'Monday';

  @override
  String get tuesday => 'Tuesday';

  @override
  String get wednesday => 'Wednesday';

  @override
  String get thursday => 'Thursday';

  @override
  String get friday => 'Friday';

  @override
  String get saturday => 'Saturday';

  @override
  String get sunday => 'Sunday';

  @override
  String get month1 => 'Jan';

  @override
  String get month2 => 'Feb';

  @override
  String get month3 => 'Mar';

  @override
  String get month4 => 'Apr';

  @override
  String get month5 => 'May';

  @override
  String get month6 => 'Jun';

  @override
  String get month7 => 'Jul';

  @override
  String get month8 => 'Aug';

  @override
  String get month9 => 'Sep';

  @override
  String get month10 => 'Oct';

  @override
  String get month11 => 'Nov';

  @override
  String get month12 => 'Dec';

  @override
  String todayDate(Object date) {
    return 'Today, $date';
  }

  @override
  String tomorrowDate(Object date) {
    return 'Tomorrow, $date';
  }

  @override
  String yesterdayDate(Object date) {
    return 'Yesterday, $date';
  }

  @override
  String get addNewTask => 'Add New Task';

  @override
  String get taskTitleHint => 'Task title...';

  @override
  String get notesOptional => 'Notes (optional)...';

  @override
  String get setTime => 'Set time';

  @override
  String get saveTask => 'Save task';

  @override
  String get taskTitle => 'Task title...';

  @override
  String get taskNotes => 'Notes';

  @override
  String get taskNotesHint =>
      'Write notes...\nSupports checklists, bullet points, freely.';

  @override
  String get alarm => 'Alarm';

  @override
  String get markDone => 'Mark as done';

  @override
  String get markDoneShort => 'Done';

  @override
  String get selectTime => 'Study time';

  @override
  String get selectDate => 'Date';

  @override
  String get expired => 'Expired';

  @override
  String get deleteTask => 'Delete task?';

  @override
  String deleteConfirm(Object title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get pastTasksTitle => 'Past Tasks';

  @override
  String get pastTasksHistory => 'Activity History';

  @override
  String get completed => 'Completed';

  @override
  String get missed => 'Missed';

  @override
  String get pastEvents => 'Past Events';

  @override
  String get byDay => 'By Day';

  @override
  String get statistics => 'Statistics';

  @override
  String get noPastTasks => 'No past tasks';

  @override
  String get noDateLabel => 'No date';

  @override
  String get completionRate => 'Completion Rate';

  @override
  String get completedOf => 'done / ... tasks';

  @override
  String get missedCount => 'Missed Tasks';

  @override
  String get missedDesc => 'Overdue tasks not completed';

  @override
  String get pastEventsCount => 'Past Events';

  @override
  String get pastEventsDesc => 'Recurring events that ended';

  @override
  String get categoryBreakdown => 'Category Breakdown';

  @override
  String get markCompleted => 'Mark as completed';

  @override
  String get reactivate => 'Reactivate (push to future)';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String get updateTitle => 'Important Update!';

  @override
  String get updateNewVersion => 'New version available';

  @override
  String updateDescription(Object version) {
    return 'A new version $version is available. Tap update to automatically install.';
  }

  @override
  String get updateSkip => 'Skip';

  @override
  String get updateNow => 'Update';

  @override
  String get updateDownloading => 'Downloading update...';

  @override
  String get updateDontClose => 'Don\'t close the app while downloading!';

  @override
  String get updateReady => 'Download complete!';

  @override
  String get updateInstallHint => 'Tap once to install the new version';

  @override
  String get updateLater => 'Later';

  @override
  String get updateInstall => 'Install now';

  @override
  String get updateFailed => 'Download failed';

  @override
  String get updateUnknownError => 'Unknown error';

  @override
  String get updateClose => 'Close';

  @override
  String get updateRetry => 'Retry';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsDay => 'DAY';

  @override
  String get statsWeek => 'WEEK';

  @override
  String get statsMonth => 'MONTH';

  @override
  String get statsToday => 'Today';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsCompleted => 'Done';

  @override
  String get statsRemaining => 'Remaining';

  @override
  String get statsRate => 'Rate';

  @override
  String get statsCategory => 'Categories';

  @override
  String get authGoogleSignIn => 'Sign in with Google';

  @override
  String get authOr => 'or';

  @override
  String get authGuest => 'Continue as guest';

  @override
  String get authEmailSignIn => 'Sign in with Email';

  @override
  String get authEmailRegister => 'Create new account';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authPasswordHint => 'Password';

  @override
  String get authConfirmPassword => 'Confirm password';

  @override
  String get authLoginButton => 'Sign in';

  @override
  String get authRegisterButton => 'Sign up';

  @override
  String get authNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get authHasAccount => 'Already have an account? Sign in';

  @override
  String get authDataSafe => 'Data is stored safely on your device';

  @override
  String get authTagline => 'Smart task management';

  @override
  String get authGoogleCancelled => 'Google sign-in was cancelled';

  @override
  String get authFillAll => 'Please enter both email and password';

  @override
  String get authEnterName => 'Please enter your name';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authWeakPassword => 'Password must be at least 6 characters';

  @override
  String get authAccountNotFound => 'Account not found';

  @override
  String get authWrongPassword => 'Wrong password';

  @override
  String get authEmailInUse => 'Email already in use';

  @override
  String get authInvalidEmail => 'Invalid email address';

  @override
  String get authTooWeak => 'Password is too weak';

  @override
  String get authNetworkError => 'Network connection error';

  @override
  String get authInvalidCredential => 'Invalid login credentials';

  @override
  String get authGenericError => 'An error occurred. Please try again.';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authPasswordResetSent =>
      'Password reset email sent. Check your inbox.';

  @override
  String get aiGreeting =>
      'Hello! I\'m SuperNote\'s AI assistant.\nYou can ask me about tasks, schedules, or ask me to analyze your work.';
}
