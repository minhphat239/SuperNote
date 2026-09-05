// ============================================
// GOOGLE APPS SCRIPT - SuperNote Feedback Handler
// ============================================
//
// HƯỚNG DẪN SETUP:
// 1. Tạo Google Sheet mới
// 2. Vào Extensions → Apps Script
// 3. Copy toàn bộ code này vào editor
// 4. Thay EMAIL_DEV_BY_BAN = "email-cua-ban@gmail.com"
// 5. Deploy → New deployment → Web app
//    - Execute as: Me
//    - Who has access: Anyone
// 6. Copy URL Web App và paste vào Settings → Feedback
//
// ============================================

// ========== CẤU HÌNH ==========
// Thay email dev vào đây!
const EMAIL_DEV = "phatngominh.hcm@gmail.com";

// Tên sheet trong Google Sheets
const SHEET_NAME = "Feedback";

// ========== CODE CHÍNH ==========

function doPost(e) {
  try {
    // Parse data từ app
    const data = JSON.parse(e.postData.contents);
    
    // Validate
    if (!data.message || data.message.trim() === '') {
      return ContentService.createTextOutput(
        JSON.stringify({ success: false, error: 'Empty message' })
      ).setMimeType(ContentService.MimeType.JSON);
    }
    
    // Ghi vào Google Sheet
    const sheet = getOrCreateSheet();
    sheet.appendRow([
      new Date(),                    // Timestamp
      data.message,                  // Message
      data.platform || 'unknown',    // Platform
      data.appVersion || 'unknown',  // App Version
      data.appBuild || 'unknown',    // Build Number
      'anonymous'                    // User ID (ẩn danh)
    ]);
    
    // Gửi email thông báo cho dev
    sendEmailToDev(data);
    
    return ContentService.createTextOutput(
      JSON.stringify({ success: true })
    ).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(
      JSON.stringify({ success: false, error: error.toString() })
    ).setMimeType(ContentService.MimeType.JSON);
  }
}

function getOrCreateSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME);
  
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
    // Thêm header
    sheet.appendRow([
      'Timestamp', 'Message', 'Platform', 'App Version', 'Build', 'User ID'
    ]);
    // Format header
    const headerRange = sheet.getRange(1, 1, 1, 6);
    headerRange.setFontWeight('bold');
    headerRange.setBackground('#4285F4');
    headerRange.setFontColor('#FFFFFF');
    // Auto-resize columns
    sheet.autoResizeColumns(1, 6);
  }
  
  return sheet;
}

function sendEmailToDev(data) {
  const subject = `📱 SuperNote Feedback - ${data.platform}`;
  
  const body = `
📱 New Feedback from SuperNote App
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Message:
${data.message}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📱 Platform: ${data.platform}
📦 Version: ${data.appVersion} (${data.appBuild})
🕐 Time: ${new Date().toLocaleString('vi-VN')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This feedback was sent anonymously from SuperNote app.
  `.trim();

  MailApp.sendEmail({
    to: EMAIL_DEV,
    subject: subject,
    body: body
  });
}

// Test function (chạy thủ công để kiểm tra)
function testFunction() {
  const testData = {
    message: "Test feedback từ Apps Script",
    platform: "test",
    appVersion: "1.0.0",
    appBuild: "1"
  };
  
  const sheet = getOrCreateSheet();
  sheet.appendRow([
    new Date(),
    testData.message,
    testData.platform,
    testData.appVersion,
    testData.appBuild,
    'test'
  ]);
  
  Logger.log("Test completed! Check your sheet.");
}
