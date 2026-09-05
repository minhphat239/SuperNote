// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'SuperNote';

  @override
  String get settings => 'Cài đặt';

  @override
  String get today => 'Hôm nay';

  @override
  String get noTask => 'Không có task';

  @override
  String get sectionAppearance => 'Giao diện';

  @override
  String get sectionCustomBg => 'Nền tùy chỉnh';

  @override
  String get sectionNotifications => 'Thông báo';

  @override
  String get sectionAccount => 'Tài khoản';

  @override
  String get sectionGemini => 'Gemini AI';

  @override
  String get sectionStorage => 'Lưu trữ';

  @override
  String get sectionLanguage => 'Ngôn ngữ';

  @override
  String get sectionTest => 'Test';

  @override
  String get sectionInfo => 'Thông tin';

  @override
  String get sectionFeatures => 'Chức năng';

  @override
  String get statsSubtitle => 'Xem biểu đồ thống kê công việc';

  @override
  String get notifSound => 'Âm thanh thông báo';

  @override
  String get notifSoundDesc => 'Phát âm thanh khi nhắc nhở';

  @override
  String get notifVibration => 'Rung khi thông báo';

  @override
  String get notifVibrationDesc => 'Rung thiết bị khi có thông báo mới';

  @override
  String get defaultPreReminder => 'Nhắc trước mặc định';

  @override
  String get quietHours => 'Giờ yên lặng';

  @override
  String get quietHoursDesc =>
      'Thông báo sẽ được tạm dừng trong khoảng thời gian này';

  @override
  String get timeStart => 'Bắt đầu';

  @override
  String get timeEnd => 'Kết thúc';

  @override
  String get detailedBackground => 'Hình nền chi tiết';

  @override
  String get detailedBackgroundDesc => 'Bật/tắt hiệu ứng orbs và animation nền';

  @override
  String get attachmentFile => 'Tệp';

  @override
  String attachmentCount(Object count) {
    return '$count tệp đính kèm';
  }

  @override
  String get attachFile => 'Đính kèm tệp';

  @override
  String get chooseFromDevice => 'Chọn tệp từ thiết bị';

  @override
  String filesAttached(Object count) {
    return '$count tệp đã đính kèm';
  }

  @override
  String get accountTitle => 'Tài khoản';

  @override
  String get accountNotLoggedIn => 'Chưa đăng nhập';

  @override
  String get accountNotLoggedInDesc => 'Mở lại màn hình đăng nhập';

  @override
  String get accountGuest => 'Khách';

  @override
  String get accountNoSync => 'Không đồng bộ';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get logoutDesc => 'Thoát khỏi tài khoản hiện tại';

  @override
  String get login => 'Đăng nhập';

  @override
  String get loginDesc => 'Đăng nhập để đồng bộ dữ liệu';

  @override
  String get loading => 'Đang tải...';

  @override
  String get languageLabel => 'Ngôn ngữ';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get languageEnglish => 'English';

  @override
  String get geminiLabel => 'Gemini AI';

  @override
  String get geminiConfigured => 'Đã cấu hình — AI đang hoạt động';

  @override
  String get geminiNotConfigured => 'Nhập API key để bật AI';

  @override
  String get geminiEnterKey => 'Nhập Gemini API Key';

  @override
  String get geminiSave => 'Lưu';

  @override
  String get storageLabel => 'Lưu trữ';

  @override
  String get pastTasks => 'Các việc đã qua';

  @override
  String get pastTasksDesc => 'Xem lại task cũ, thống kê hiệu suất';

  @override
  String get customBgActiveVideo => 'Video nền đang active';

  @override
  String get customBgActiveImage => 'Hình nền đang active';

  @override
  String get customBgChoose => 'Chọn hình/video nền';

  @override
  String get customBgDesc => 'JPG, PNG, MP4, MOV (tối đa 50 MB)';

  @override
  String get customBgTapToChange => 'Nhấn để thay đổi';

  @override
  String get customBgRemove => 'Xóa nền tùy chỉnh';

  @override
  String get customBgRemoveDesc => 'Quay về nền mặc định (Neon Orbs)';

  @override
  String get customBgUpdated => 'Nền tùy chỉnh đã được cập nhật!';

  @override
  String get customBgRemoved => 'Đã xóa nền tùy chỉnh';

  @override
  String get testNotif => 'Gửi thông báo test';

  @override
  String get testNotifDesc => 'Kiểm tra thông báo hoạt động';

  @override
  String get testGemini => 'Test Gemini API';

  @override
  String get addTask => 'Thêm task';

  @override
  String get addTaskDesc => 'Thêm task nhanh';

  @override
  String get addTaskQuick => 'Thêm nhanh task...';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get snooze => 'Tạm hoãn';

  @override
  String get edit => 'Sửa';

  @override
  String get done => 'Xong';

  @override
  String get pending => 'Đang chờ';

  @override
  String get snoozed => 'Tạm hoãn';

  @override
  String get morning => 'Buổi sáng';

  @override
  String get afternoon => 'Buổi chiều';

  @override
  String get evening => 'Buổi tối';

  @override
  String get allDay => 'Cả ngày';

  @override
  String get taskCount => 'việc';

  @override
  String get taskCountLabel => 'việc';

  @override
  String get timelineToday => 'Hôm nay';

  @override
  String get timelineThisWeek => 'Tuần này';

  @override
  String get timelineUpcoming => 'Sắp tới';

  @override
  String get timelinePast => 'Đã qua';

  @override
  String get noSchedule => 'Không có lịch trình';

  @override
  String get noScheduleDesc => 'Chưa có task nào được lên lịch';

  @override
  String get quickTask => 'Thêm task nhanh';

  @override
  String get taskToday => 'việc hôm nay';

  @override
  String get progressLabel => 'Tiến độ hôm nay';

  @override
  String get progressDetail => 'việc đã hoàn thành';

  @override
  String get appVersion => 'SuperNote';

  @override
  String appVersionDesc(Object version) {
    return 'v$version — Smart reminder app for students';
  }

  @override
  String get deleteTaskTitle => 'Xóa task';

  @override
  String deleteTaskConfirm(Object title) {
    return 'Xóa \"$title\"?';
  }

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterClass => 'Lớp học';

  @override
  String get filterExam => 'Kỳ thi';

  @override
  String get filterAssignment => 'Bài tập';

  @override
  String get filterPersonal => 'Cá nhân';

  @override
  String get overdue => 'Quá hạn';

  @override
  String get thisWeek => 'Tuần này';

  @override
  String get later => 'Sau đó';

  @override
  String get noDate => 'Không có ngày';

  @override
  String get emptyRelax => 'Hôm nay thật thư giãn — chưa có task nào!';

  @override
  String get emptyRelaxDesc => 'Tận hưởng ngày mới, task sẽ đến sau.';

  @override
  String get emptyDone => 'Đã xong hết rồi, nghỉ ngơi thôi!';

  @override
  String get emptyFree => 'Một ngày trống trải — hãy thêm task mới.';

  @override
  String get emptyHint => 'Nhập task ở ô phía trên';

  @override
  String get calendarTitle => 'Lịch';

  @override
  String get timelineTitle => 'Dòng thời gian';

  @override
  String get tasksTitle => 'Công việc';

  @override
  String get weekdayMon => 'T2';

  @override
  String get weekdayTue => 'T3';

  @override
  String get weekdayWed => 'T4';

  @override
  String get weekdayThu => 'T5';

  @override
  String get weekdayFri => 'T6';

  @override
  String get weekdaySat => 'T7';

  @override
  String get weekdaySun => 'CN';

  @override
  String get todayButton => 'Hôm nay';

  @override
  String get upcomingTasks => 'Công việc sắp tới';

  @override
  String get noUpcoming => 'Không có task nào sắp tới';

  @override
  String get addTaskForDay => 'Thêm task cho ngày này';

  @override
  String get tomorrow => 'Ngày mai';

  @override
  String daysLeft(Object days) {
    return 'Còn $days ngày';
  }

  @override
  String get monday => 'Thứ Hai';

  @override
  String get tuesday => 'Thứ Ba';

  @override
  String get wednesday => 'Thứ Tư';

  @override
  String get thursday => 'Thứ Năm';

  @override
  String get friday => 'Thứ Sáu';

  @override
  String get saturday => 'Thứ Bảy';

  @override
  String get sunday => 'Chủ Nhật';

  @override
  String get month1 => 'tháng 1';

  @override
  String get month2 => 'tháng 2';

  @override
  String get month3 => 'tháng 3';

  @override
  String get month4 => 'tháng 4';

  @override
  String get month5 => 'tháng 5';

  @override
  String get month6 => 'tháng 6';

  @override
  String get month7 => 'tháng 7';

  @override
  String get month8 => 'tháng 8';

  @override
  String get month9 => 'tháng 9';

  @override
  String get month10 => 'tháng 10';

  @override
  String get month11 => 'tháng 11';

  @override
  String get month12 => 'tháng 12';

  @override
  String todayDate(Object date) {
    return 'Hôm nay, $date';
  }

  @override
  String tomorrowDate(Object date) {
    return 'Ngày mai, $date';
  }

  @override
  String yesterdayDate(Object date) {
    return 'Hôm qua, $date';
  }

  @override
  String get addNewTask => 'Thêm task mới';

  @override
  String get taskTitleHint => 'Tiêu đề task...';

  @override
  String get notesOptional => 'Ghi chú (tuỳ chọn)...';

  @override
  String get setTime => 'Đặt giờ';

  @override
  String get saveTask => 'Lưu task';

  @override
  String get taskTitle => 'Tiêu đề task...';

  @override
  String get taskNotes => 'Ghi chú';

  @override
  String get taskNotesHint =>
      'Viết ghi chú...\nHỗ trợ checklist, bullet points, freely.';

  @override
  String get alarm => 'Báo thức';

  @override
  String get markDone => 'Đánh dấu xong';

  @override
  String get markDoneShort => 'Xong';

  @override
  String get selectTime => 'Giờ học';

  @override
  String get selectDate => 'Ngày';

  @override
  String get expired => 'Quá hạn';

  @override
  String get deleteTask => 'Xóa task?';

  @override
  String deleteConfirm(Object title) {
    return 'Xóa \"$title\"?';
  }

  @override
  String get pastTasksTitle => 'Các việc đã qua';

  @override
  String get pastTasksHistory => 'Lịch sử hoạt động';

  @override
  String get completed => 'Đã làm';

  @override
  String get missed => 'Quên làm';

  @override
  String get pastEvents => 'Event cũ';

  @override
  String get byDay => 'Theo ngày';

  @override
  String get statistics => 'Thống kê';

  @override
  String get noPastTasks => 'Không có việc nào';

  @override
  String get noDateLabel => 'Không ngày';

  @override
  String get completionRate => 'Tỷ lệ hoàn thành';

  @override
  String get completedOf => 'đã làm / ... việc';

  @override
  String get missedCount => 'Đã quên làm';

  @override
  String get missedDesc => 'Việc quá hạn chưa hoàn thành';

  @override
  String get pastEventsCount => 'Event đã qua';

  @override
  String get pastEventsDesc => 'Sự kiện lặp lại đã kết thúc';

  @override
  String get categoryBreakdown => 'Phân loại';

  @override
  String get markCompleted => 'Đánh dấu hoàn thành';

  @override
  String get reactivate => 'Tái kích hoạt (đẩy về tương lai)';

  @override
  String get deletePermanently => 'Xóa vĩnh viễn';

  @override
  String get updateTitle => 'Cập nhật quan trọng!';

  @override
  String get updateNewVersion => 'Có phiên bản mới';

  @override
  String updateDescription(Object version) {
    return 'App đã có phiên bản mới: $version, vui lòng bấm cập nhật để tự động cập nhật';
  }

  @override
  String get updateSkip => 'Bỏ qua';

  @override
  String get updateNow => 'Cập nhật';

  @override
  String get updateDownloading => 'Đang tải bản cập nhật...';

  @override
  String get updateDontClose => 'Đừng đóng app trong khi tải nhé!';

  @override
  String get updateReady => 'Tải xong rồi!';

  @override
  String get updateInstallHint => 'Bấm 1 lần để cài đặt phiên bản mới';

  @override
  String get updateLater => 'Để sau';

  @override
  String get updateInstall => 'Cài đặt ngay';

  @override
  String get updateFailed => 'Tải xuống thất bại';

  @override
  String get updateUnknownError => 'Lỗi không xác định';

  @override
  String get updateClose => 'Đóng';

  @override
  String get updateRetry => 'Thử lại';

  @override
  String get statsTitle => 'Thống kê';

  @override
  String get statsDay => 'NGÀY';

  @override
  String get statsWeek => 'TUẦN';

  @override
  String get statsMonth => 'THÁNG';

  @override
  String get statsToday => 'Hôm nay';

  @override
  String get statsThisWeek => 'Tuần này';

  @override
  String get statsThisMonth => 'Tháng này';

  @override
  String get statsCompleted => 'Xong';

  @override
  String get statsRemaining => 'Còn lại';

  @override
  String get statsRate => 'Tỷ lệ';

  @override
  String get statsCategory => 'Phân loại';

  @override
  String get authGoogleSignIn => 'Đăng nhập bằng Google';

  @override
  String get authOr => 'hoặc';

  @override
  String get authGuest => 'Sử dụng ngay (khách)';

  @override
  String get authEmailSignIn => 'Đăng nhập bằng Email';

  @override
  String get authEmailRegister => 'Tạo tài khoản mới';

  @override
  String get authNameHint => 'Tên của bạn';

  @override
  String get authPasswordHint => 'Mật khẩu';

  @override
  String get authConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get authLoginButton => 'Đăng nhập';

  @override
  String get authRegisterButton => 'Đăng ký';

  @override
  String get authNoAccount => 'Chưa có tài khoản? Đăng ký ngay';

  @override
  String get authHasAccount => 'Đã có tài khoản? Đăng nhập';

  @override
  String get authDataSafe => 'Dữ liệu được lưu trữ an toàn trên thiết bị';

  @override
  String get authTagline => 'Quản lý công việc thông minh';

  @override
  String get authGoogleCancelled => 'Bạn đã hủy chọn tài khoản Google';

  @override
  String get authFillAll => 'Vui lòng nhập đầy đủ email và mật khẩu';

  @override
  String get authEnterName => 'Vui lòng nhập tên';

  @override
  String get authPasswordMismatch => 'Mật khẩu xác nhận không khớp';

  @override
  String get authWeakPassword => 'Mật khẩu phải có ít nhất 6 ký tự';

  @override
  String get authAccountNotFound => 'Không tìm thấy tài khoản';

  @override
  String get authWrongPassword => 'Sai mật khẩu';

  @override
  String get authEmailInUse => 'Email đã được sử dụng';

  @override
  String get authInvalidEmail => 'Email không hợp lệ';

  @override
  String get authTooWeak => 'Mật khẩu quá yếu';

  @override
  String get authNetworkError => 'Lỗi kết nối mạng';

  @override
  String get authInvalidCredential => 'Thông tin đăng nhập không hợp lệ';

  @override
  String get authGenericError => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String get authForgotPassword => 'Quên mật khẩu?';

  @override
  String get authPasswordResetSent =>
      'Đã gửi email đặt lại mật khẩu. Kiểm tra hộp thư.';

  @override
  String get aiGreeting =>
      'Xin chào! Mình là AI trợ lý của SuperNote.\nBạn có thể hỏi mình về task, lịch trình, hoặc nhờ mình phân tích công việc.';

  @override
  String get feedback => 'Phản hồi';

  @override
  String get feedbackTitle => 'Gửi phản hồi';

  @override
  String get feedbackSubtitle => 'Báo lỗi hoặc gợi ý cải thiện';

  @override
  String get feedbackDesc =>
      'Phản hồi của bạn giúp chúng tôi cải thiện ứng dụng. Nó sẽ được gửi ẩn danh đến đội ngũ phát triển.';

  @override
  String get feedbackHint => 'Mô tả lỗi hoặc gợi ý của bạn...';

  @override
  String get feedbackSubmit => 'Gửi phản hồi';

  @override
  String get feedbackSuccess => 'Gửi phản hồi thành công! Cảm ơn bạn.';

  @override
  String get feedbackError => 'Gửi phản hồi thất bại. Vui lòng thử lại.';

  @override
  String get feedbackSetup => 'Cài đặt Phản hồi';

  @override
  String get feedbackSetupDesc =>
      'Nhập URL Google Apps Script Web App để nhận phản hồi.';

  @override
  String get feedbackSetupSave => 'Lưu URL';

  @override
  String get feedbackChangeUrl => 'Đổi URL';

  @override
  String get feedbackUrlCleared => 'Đã xóa URL';
}
