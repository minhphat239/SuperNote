import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'SuperNote'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @noTask.
  ///
  /// In vi, this message translates to:
  /// **'Không có task'**
  String get noTask;

  /// No description provided for @sectionAppearance.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện'**
  String get sectionAppearance;

  /// No description provided for @sectionCustomBg.
  ///
  /// In vi, this message translates to:
  /// **'Nền tùy chỉnh'**
  String get sectionCustomBg;

  /// No description provided for @sectionNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get sectionNotifications;

  /// No description provided for @sectionAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get sectionAccount;

  /// No description provided for @sectionGemini.
  ///
  /// In vi, this message translates to:
  /// **'Gemini AI'**
  String get sectionGemini;

  /// No description provided for @sectionStorage.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ'**
  String get sectionStorage;

  /// No description provided for @sectionLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get sectionLanguage;

  /// No description provided for @sectionTest.
  ///
  /// In vi, this message translates to:
  /// **'Test'**
  String get sectionTest;

  /// No description provided for @sectionInfo.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get sectionInfo;

  /// No description provided for @sectionFeatures.
  ///
  /// In vi, this message translates to:
  /// **'Chức năng'**
  String get sectionFeatures;

  /// No description provided for @statsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xem biểu đồ thống kê công việc'**
  String get statsSubtitle;

  /// No description provided for @notifSound.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh thông báo'**
  String get notifSound;

  /// No description provided for @notifSoundDesc.
  ///
  /// In vi, this message translates to:
  /// **'Phát âm thanh khi nhắc nhở'**
  String get notifSoundDesc;

  /// No description provided for @notifVibration.
  ///
  /// In vi, this message translates to:
  /// **'Rung khi thông báo'**
  String get notifVibration;

  /// No description provided for @notifVibrationDesc.
  ///
  /// In vi, this message translates to:
  /// **'Rung thiết bị khi có thông báo mới'**
  String get notifVibrationDesc;

  /// No description provided for @defaultPreReminder.
  ///
  /// In vi, this message translates to:
  /// **'Nhắc trước mặc định'**
  String get defaultPreReminder;

  /// No description provided for @quietHours.
  ///
  /// In vi, this message translates to:
  /// **'Giờ yên lặng'**
  String get quietHours;

  /// No description provided for @quietHoursDesc.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo sẽ được tạm dừng trong khoảng thời gian này'**
  String get quietHoursDesc;

  /// No description provided for @accountTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get accountTitle;

  /// No description provided for @accountNotLoggedIn.
  ///
  /// In vi, this message translates to:
  /// **'Chưa đăng nhập'**
  String get accountNotLoggedIn;

  /// No description provided for @accountNotLoggedInDesc.
  ///
  /// In vi, this message translates to:
  /// **'Mở lại màn hình đăng nhập'**
  String get accountNotLoggedInDesc;

  /// No description provided for @accountGuest.
  ///
  /// In vi, this message translates to:
  /// **'Khách'**
  String get accountGuest;

  /// No description provided for @accountNoSync.
  ///
  /// In vi, this message translates to:
  /// **'Không đồng bộ'**
  String get accountNoSync;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @logoutDesc.
  ///
  /// In vi, this message translates to:
  /// **'Thoát khỏi tài khoản hiện tại'**
  String get logoutDesc;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @loginDesc.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để đồng bộ dữ liệu'**
  String get loginDesc;

  /// No description provided for @loading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get loading;

  /// No description provided for @languageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get languageLabel;

  /// No description provided for @languageVietnamese.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In vi, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @geminiLabel.
  ///
  /// In vi, this message translates to:
  /// **'Gemini AI'**
  String get geminiLabel;

  /// No description provided for @geminiConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Đã cấu hình — AI đang hoạt động'**
  String get geminiConfigured;

  /// No description provided for @geminiNotConfigured.
  ///
  /// In vi, this message translates to:
  /// **'Nhập API key để bật AI'**
  String get geminiNotConfigured;

  /// No description provided for @geminiEnterKey.
  ///
  /// In vi, this message translates to:
  /// **'Nhập Gemini API Key'**
  String get geminiEnterKey;

  /// No description provided for @geminiSave.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get geminiSave;

  /// No description provided for @storageLabel.
  ///
  /// In vi, this message translates to:
  /// **'Lưu trữ'**
  String get storageLabel;

  /// No description provided for @pastTasks.
  ///
  /// In vi, this message translates to:
  /// **'Các việc đã qua'**
  String get pastTasks;

  /// No description provided for @pastTasksDesc.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại task cũ, thống kê hiệu suất'**
  String get pastTasksDesc;

  /// No description provided for @customBgActiveVideo.
  ///
  /// In vi, this message translates to:
  /// **'Video nền đang active'**
  String get customBgActiveVideo;

  /// No description provided for @customBgActiveImage.
  ///
  /// In vi, this message translates to:
  /// **'Hình nền đang active'**
  String get customBgActiveImage;

  /// No description provided for @customBgChoose.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hình/video nền'**
  String get customBgChoose;

  /// No description provided for @customBgDesc.
  ///
  /// In vi, this message translates to:
  /// **'JPG, PNG, MP4, MOV (tối đa 50 MB)'**
  String get customBgDesc;

  /// No description provided for @customBgTapToChange.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn để thay đổi'**
  String get customBgTapToChange;

  /// No description provided for @customBgRemove.
  ///
  /// In vi, this message translates to:
  /// **'Xóa nền tùy chỉnh'**
  String get customBgRemove;

  /// No description provided for @customBgRemoveDesc.
  ///
  /// In vi, this message translates to:
  /// **'Quay về nền mặc định (Neon Orbs)'**
  String get customBgRemoveDesc;

  /// No description provided for @customBgUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Nền tùy chỉnh đã được cập nhật!'**
  String get customBgUpdated;

  /// No description provided for @customBgRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa nền tùy chỉnh'**
  String get customBgRemoved;

  /// No description provided for @testNotif.
  ///
  /// In vi, this message translates to:
  /// **'Gửi thông báo test'**
  String get testNotif;

  /// No description provided for @testNotifDesc.
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra thông báo hoạt động'**
  String get testNotifDesc;

  /// No description provided for @testGemini.
  ///
  /// In vi, this message translates to:
  /// **'Test Gemini API'**
  String get testGemini;

  /// No description provided for @addTask.
  ///
  /// In vi, this message translates to:
  /// **'Thêm task'**
  String get addTask;

  /// No description provided for @addTaskDesc.
  ///
  /// In vi, this message translates to:
  /// **'Thêm task nhanh'**
  String get addTaskDesc;

  /// No description provided for @addTaskQuick.
  ///
  /// In vi, this message translates to:
  /// **'Thêm nhanh task...'**
  String get addTaskQuick;

  /// No description provided for @save.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xóa'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In vi, this message translates to:
  /// **'Sửa'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get done;

  /// No description provided for @pending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get pending;

  /// No description provided for @snoozed.
  ///
  /// In vi, this message translates to:
  /// **'Tạm hoãn'**
  String get snoozed;

  /// No description provided for @morning.
  ///
  /// In vi, this message translates to:
  /// **'Buổi sáng'**
  String get morning;

  /// No description provided for @afternoon.
  ///
  /// In vi, this message translates to:
  /// **'Buổi chiều'**
  String get afternoon;

  /// No description provided for @evening.
  ///
  /// In vi, this message translates to:
  /// **'Buổi tối'**
  String get evening;

  /// No description provided for @allDay.
  ///
  /// In vi, this message translates to:
  /// **'Cả ngày'**
  String get allDay;

  /// No description provided for @taskCount.
  ///
  /// In vi, this message translates to:
  /// **'việc'**
  String get taskCount;

  /// No description provided for @taskCountLabel.
  ///
  /// In vi, this message translates to:
  /// **'việc'**
  String get taskCountLabel;

  /// No description provided for @timelineToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get timelineToday;

  /// No description provided for @timelineThisWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này'**
  String get timelineThisWeek;

  /// No description provided for @timelineUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Sắp tới'**
  String get timelineUpcoming;

  /// No description provided for @timelinePast.
  ///
  /// In vi, this message translates to:
  /// **'Đã qua'**
  String get timelinePast;

  /// No description provided for @noSchedule.
  ///
  /// In vi, this message translates to:
  /// **'Không có lịch trình'**
  String get noSchedule;

  /// No description provided for @noScheduleDesc.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có task nào được lên lịch'**
  String get noScheduleDesc;

  /// No description provided for @quickTask.
  ///
  /// In vi, this message translates to:
  /// **'Thêm task nhanh'**
  String get quickTask;

  /// No description provided for @taskToday.
  ///
  /// In vi, this message translates to:
  /// **'việc hôm nay'**
  String get taskToday;

  /// No description provided for @progressLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ hôm nay'**
  String get progressLabel;

  /// No description provided for @progressDetail.
  ///
  /// In vi, this message translates to:
  /// **'việc đã hoàn thành'**
  String get progressDetail;

  /// No description provided for @appVersion.
  ///
  /// In vi, this message translates to:
  /// **'SuperNote'**
  String get appVersion;

  /// No description provided for @appVersionDesc.
  ///
  /// In vi, this message translates to:
  /// **'v{version} — Smart reminder app for students'**
  String appVersionDesc(Object version);

  /// No description provided for @deleteTaskTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa task'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa \"{title}\"?'**
  String deleteTaskConfirm(Object title);

  /// No description provided for @filterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get filterAll;

  /// No description provided for @filterClass.
  ///
  /// In vi, this message translates to:
  /// **'Lớp học'**
  String get filterClass;

  /// No description provided for @filterExam.
  ///
  /// In vi, this message translates to:
  /// **'Kỳ thi'**
  String get filterExam;

  /// No description provided for @filterAssignment.
  ///
  /// In vi, this message translates to:
  /// **'Bài tập'**
  String get filterAssignment;

  /// No description provided for @filterPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get filterPersonal;

  /// No description provided for @overdue.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn'**
  String get overdue;

  /// No description provided for @thisWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này'**
  String get thisWeek;

  /// No description provided for @later.
  ///
  /// In vi, this message translates to:
  /// **'Sau đó'**
  String get later;

  /// No description provided for @noDate.
  ///
  /// In vi, this message translates to:
  /// **'Không có ngày'**
  String get noDate;

  /// No description provided for @emptyRelax.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay thật thư giãn — chưa có task nào!'**
  String get emptyRelax;

  /// No description provided for @emptyRelaxDesc.
  ///
  /// In vi, this message translates to:
  /// **'Tận hưởng ngày mới, task sẽ đến sau.'**
  String get emptyRelaxDesc;

  /// No description provided for @emptyDone.
  ///
  /// In vi, this message translates to:
  /// **'Đã xong hết rồi, nghỉ ngơi thôi!'**
  String get emptyDone;

  /// No description provided for @emptyFree.
  ///
  /// In vi, this message translates to:
  /// **'Một ngày trống trải — hãy thêm task mới.'**
  String get emptyFree;

  /// No description provided for @emptyHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập task ở ô phía trên'**
  String get emptyHint;

  /// No description provided for @calendarTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch'**
  String get calendarTitle;

  /// No description provided for @todayButton.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get todayButton;

  /// No description provided for @upcomingTasks.
  ///
  /// In vi, this message translates to:
  /// **'Công việc sắp tới'**
  String get upcomingTasks;

  /// No description provided for @noUpcoming.
  ///
  /// In vi, this message translates to:
  /// **'Không có task nào sắp tới'**
  String get noUpcoming;

  /// No description provided for @addTaskForDay.
  ///
  /// In vi, this message translates to:
  /// **'Thêm task cho ngày này'**
  String get addTaskForDay;

  /// No description provided for @tomorrow.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai'**
  String get tomorrow;

  /// No description provided for @daysLeft.
  ///
  /// In vi, this message translates to:
  /// **'Còn {days} ngày'**
  String daysLeft(Object days);

  /// No description provided for @monday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Hai'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Ba'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Tư'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Năm'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Sáu'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In vi, this message translates to:
  /// **'Thứ Bảy'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In vi, this message translates to:
  /// **'Chủ Nhật'**
  String get sunday;

  /// No description provided for @month1.
  ///
  /// In vi, this message translates to:
  /// **'tháng 1'**
  String get month1;

  /// No description provided for @month2.
  ///
  /// In vi, this message translates to:
  /// **'tháng 2'**
  String get month2;

  /// No description provided for @month3.
  ///
  /// In vi, this message translates to:
  /// **'tháng 3'**
  String get month3;

  /// No description provided for @month4.
  ///
  /// In vi, this message translates to:
  /// **'tháng 4'**
  String get month4;

  /// No description provided for @month5.
  ///
  /// In vi, this message translates to:
  /// **'tháng 5'**
  String get month5;

  /// No description provided for @month6.
  ///
  /// In vi, this message translates to:
  /// **'tháng 6'**
  String get month6;

  /// No description provided for @month7.
  ///
  /// In vi, this message translates to:
  /// **'tháng 7'**
  String get month7;

  /// No description provided for @month8.
  ///
  /// In vi, this message translates to:
  /// **'tháng 8'**
  String get month8;

  /// No description provided for @month9.
  ///
  /// In vi, this message translates to:
  /// **'tháng 9'**
  String get month9;

  /// No description provided for @month10.
  ///
  /// In vi, this message translates to:
  /// **'tháng 10'**
  String get month10;

  /// No description provided for @month11.
  ///
  /// In vi, this message translates to:
  /// **'tháng 11'**
  String get month11;

  /// No description provided for @month12.
  ///
  /// In vi, this message translates to:
  /// **'tháng 12'**
  String get month12;

  /// No description provided for @todayDate.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay, {date}'**
  String todayDate(Object date);

  /// No description provided for @tomorrowDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày mai, {date}'**
  String tomorrowDate(Object date);

  /// No description provided for @yesterdayDate.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua, {date}'**
  String yesterdayDate(Object date);

  /// No description provided for @addNewTask.
  ///
  /// In vi, this message translates to:
  /// **'Thêm task mới'**
  String get addNewTask;

  /// No description provided for @taskTitleHint.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu đề task...'**
  String get taskTitleHint;

  /// No description provided for @notesOptional.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú (tuỳ chọn)...'**
  String get notesOptional;

  /// No description provided for @setTime.
  ///
  /// In vi, this message translates to:
  /// **'Đặt giờ'**
  String get setTime;

  /// No description provided for @saveTask.
  ///
  /// In vi, this message translates to:
  /// **'Lưu task'**
  String get saveTask;

  /// No description provided for @taskTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tiêu đề task...'**
  String get taskTitle;

  /// No description provided for @taskNotes.
  ///
  /// In vi, this message translates to:
  /// **'Ghi chú'**
  String get taskNotes;

  /// No description provided for @taskNotesHint.
  ///
  /// In vi, this message translates to:
  /// **'Viết ghi chú...\nHỗ trợ checklist, bullet points, freely.'**
  String get taskNotesHint;

  /// No description provided for @alarm.
  ///
  /// In vi, this message translates to:
  /// **'Báo thức'**
  String get alarm;

  /// No description provided for @markDone.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu xong'**
  String get markDone;

  /// No description provided for @markDoneShort.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get markDoneShort;

  /// No description provided for @selectTime.
  ///
  /// In vi, this message translates to:
  /// **'Giờ học'**
  String get selectTime;

  /// No description provided for @selectDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get selectDate;

  /// No description provided for @expired.
  ///
  /// In vi, this message translates to:
  /// **'Quá hạn'**
  String get expired;

  /// No description provided for @deleteTask.
  ///
  /// In vi, this message translates to:
  /// **'Xóa task?'**
  String get deleteTask;

  /// No description provided for @deleteConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa \"{title}\"?'**
  String deleteConfirm(Object title);

  /// No description provided for @pastTasksTitle.
  ///
  /// In vi, this message translates to:
  /// **'Các việc đã qua'**
  String get pastTasksTitle;

  /// No description provided for @pastTasksHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử hoạt động'**
  String get pastTasksHistory;

  /// No description provided for @completed.
  ///
  /// In vi, this message translates to:
  /// **'Đã làm'**
  String get completed;

  /// No description provided for @missed.
  ///
  /// In vi, this message translates to:
  /// **'Quên làm'**
  String get missed;

  /// No description provided for @pastEvents.
  ///
  /// In vi, this message translates to:
  /// **'Event cũ'**
  String get pastEvents;

  /// No description provided for @byDay.
  ///
  /// In vi, this message translates to:
  /// **'Theo ngày'**
  String get byDay;

  /// No description provided for @statistics.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get statistics;

  /// No description provided for @noPastTasks.
  ///
  /// In vi, this message translates to:
  /// **'Không có việc nào'**
  String get noPastTasks;

  /// No description provided for @noDateLabel.
  ///
  /// In vi, this message translates to:
  /// **'Không ngày'**
  String get noDateLabel;

  /// No description provided for @completionRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ hoàn thành'**
  String get completionRate;

  /// No description provided for @completedOf.
  ///
  /// In vi, this message translates to:
  /// **'đã làm / ... việc'**
  String get completedOf;

  /// No description provided for @missedCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã quên làm'**
  String get missedCount;

  /// No description provided for @missedDesc.
  ///
  /// In vi, this message translates to:
  /// **'Việc quá hạn chưa hoàn thành'**
  String get missedDesc;

  /// No description provided for @pastEventsCount.
  ///
  /// In vi, this message translates to:
  /// **'Event đã qua'**
  String get pastEventsCount;

  /// No description provided for @pastEventsDesc.
  ///
  /// In vi, this message translates to:
  /// **'Sự kiện lặp lại đã kết thúc'**
  String get pastEventsDesc;

  /// No description provided for @categoryBreakdown.
  ///
  /// In vi, this message translates to:
  /// **'Phân loại'**
  String get categoryBreakdown;

  /// No description provided for @markCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu hoàn thành'**
  String get markCompleted;

  /// No description provided for @reactivate.
  ///
  /// In vi, this message translates to:
  /// **'Tái kích hoạt (đẩy về tương lai)'**
  String get reactivate;

  /// No description provided for @deletePermanently.
  ///
  /// In vi, this message translates to:
  /// **'Xóa vĩnh viễn'**
  String get deletePermanently;

  /// No description provided for @updateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật quan trọng!'**
  String get updateTitle;

  /// No description provided for @updateNewVersion.
  ///
  /// In vi, this message translates to:
  /// **'Có phiên bản mới'**
  String get updateNewVersion;

  /// No description provided for @updateSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua'**
  String get updateSkip;

  /// No description provided for @updateNow.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ngay'**
  String get updateNow;

  /// No description provided for @updateDownloading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải bản cập nhật...'**
  String get updateDownloading;

  /// No description provided for @updateDontClose.
  ///
  /// In vi, this message translates to:
  /// **'Đừng đóng app trong khi tải nhé!'**
  String get updateDontClose;

  /// No description provided for @updateReady.
  ///
  /// In vi, this message translates to:
  /// **'Tải xong rồi!'**
  String get updateReady;

  /// No description provided for @updateInstallHint.
  ///
  /// In vi, this message translates to:
  /// **'Bấm 1 lần để cài đặt phiên bản mới'**
  String get updateInstallHint;

  /// No description provided for @updateLater.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get updateLater;

  /// No description provided for @updateInstall.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt ngay'**
  String get updateInstall;

  /// No description provided for @updateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Tải xuống thất bại'**
  String get updateFailed;

  /// No description provided for @updateUnknownError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi không xác định'**
  String get updateUnknownError;

  /// No description provided for @updateClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get updateClose;

  /// No description provided for @updateRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get updateRetry;

  /// No description provided for @statsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thống kê'**
  String get statsTitle;

  /// No description provided for @statsDay.
  ///
  /// In vi, this message translates to:
  /// **'NGÀY'**
  String get statsDay;

  /// No description provided for @statsWeek.
  ///
  /// In vi, this message translates to:
  /// **'TUẦN'**
  String get statsWeek;

  /// No description provided for @statsMonth.
  ///
  /// In vi, this message translates to:
  /// **'THÁNG'**
  String get statsMonth;

  /// No description provided for @statsToday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get statsToday;

  /// No description provided for @statsThisWeek.
  ///
  /// In vi, this message translates to:
  /// **'Tuần này'**
  String get statsThisWeek;

  /// No description provided for @statsThisMonth.
  ///
  /// In vi, this message translates to:
  /// **'Tháng này'**
  String get statsThisMonth;

  /// No description provided for @statsCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get statsCompleted;

  /// No description provided for @statsRemaining.
  ///
  /// In vi, this message translates to:
  /// **'Còn lại'**
  String get statsRemaining;

  /// No description provided for @statsRate.
  ///
  /// In vi, this message translates to:
  /// **'Tỷ lệ'**
  String get statsRate;

  /// No description provided for @statsCategory.
  ///
  /// In vi, this message translates to:
  /// **'Phân loại'**
  String get statsCategory;

  /// No description provided for @authGoogleSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Google'**
  String get authGoogleSignIn;

  /// No description provided for @authOr.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get authOr;

  /// No description provided for @authGuest.
  ///
  /// In vi, this message translates to:
  /// **'Sử dụng ngay (khách)'**
  String get authGuest;

  /// No description provided for @authEmailSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Email'**
  String get authEmailSignIn;

  /// No description provided for @authEmailRegister.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản mới'**
  String get authEmailRegister;

  /// No description provided for @authNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Tên của bạn'**
  String get authNameHint;

  /// No description provided for @authPasswordHint.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get authPasswordHint;

  /// No description provided for @authConfirmPassword.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận mật khẩu'**
  String get authConfirmPassword;

  /// No description provided for @authLoginButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get authRegisterButton;

  /// No description provided for @authNoAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? Đăng ký ngay'**
  String get authNoAccount;

  /// No description provided for @authHasAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? Đăng nhập'**
  String get authHasAccount;

  /// No description provided for @authDataSafe.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu được lưu trữ an toàn trên thiết bị'**
  String get authDataSafe;

  /// No description provided for @authTagline.
  ///
  /// In vi, this message translates to:
  /// **'Quản lý công việc thông minh'**
  String get authTagline;

  /// No description provided for @authGoogleCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã hủy chọn tài khoản Google'**
  String get authGoogleCancelled;

  /// No description provided for @authFillAll.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập đầy đủ email và mật khẩu'**
  String get authFillAll;

  /// No description provided for @authEnterName.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập tên'**
  String get authEnterName;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu xác nhận không khớp'**
  String get authPasswordMismatch;

  /// No description provided for @authWeakPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu phải có ít nhất 6 ký tự'**
  String get authWeakPassword;

  /// No description provided for @authAccountNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy tài khoản'**
  String get authAccountNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In vi, this message translates to:
  /// **'Sai mật khẩu'**
  String get authWrongPassword;

  /// No description provided for @authEmailInUse.
  ///
  /// In vi, this message translates to:
  /// **'Email đã được sử dụng'**
  String get authEmailInUse;

  /// No description provided for @authInvalidEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email không hợp lệ'**
  String get authInvalidEmail;

  /// No description provided for @authTooWeak.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu quá yếu'**
  String get authTooWeak;

  /// No description provided for @authNetworkError.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi kết nối mạng'**
  String get authNetworkError;

  /// No description provided for @authInvalidCredential.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin đăng nhập không hợp lệ'**
  String get authInvalidCredential;

  /// No description provided for @authGenericError.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi. Vui lòng thử lại.'**
  String get authGenericError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
