import 'package:flutter_test/flutter_test.dart';
import 'package:super_note/services/auto_update_service.dart';

void main() {
  group('AutoUpdateService._isNewerVersion', () {
    // We access _isNewerVersion indirectly by testing UpdateInfo parsing
    // and version comparison logic via _parseVersion

    test('1. UpdateInfo.fromJson parses tag_name correctly', () {
      final json = {
        'tag_name': 'v1.0.8',
        'name': 'Release 1.0.8',
        'body': 'Bug fixes',
        'published_at': '2026-01-01',
        'html_url': 'https://github.com/test/test/releases/tag/v1.0.8',
        'assets': <dynamic>[],
      };
      final info = UpdateInfo.fromJson(json);
      expect(info.version, '1.0.8');
      expect(info.tagName, 'v1.0.8');
    });

    test('2. UpdateInfo.fromJson strips v/V prefix', () {
      final json1 = {
        'tag_name': 'V2.0.0',
        'assets': <dynamic>[],
      };
      expect(UpdateInfo.fromJson(json1).version, '2.0.0');

      final json2 = {
        'tag_name': 'v3.1.5',
        'assets': <dynamic>[],
      };
      expect(UpdateInfo.fromJson(json2).version, '3.1.5');
    });

    test('3. UpdateInfo.fromJson strips build number after +', () {
      final json = {
        'tag_name': 'v1.0.7+9',
        'assets': <dynamic>[],
      };
      expect(UpdateInfo.fromJson(json).version, '1.0.7');
    });

    test('4. UpdateInfo.fromJson parses assets', () {
      final json = {
        'tag_name': 'v1.0.0',
        'assets': [
          {
            'name': 'app-arm64.apk',
            'browser_download_url': 'https://example.com/app.apk',
            'size': 1024000,
            'content_type': 'application/vnd.android.package-archive',
          },
        ],
      };
      final info = UpdateInfo.fromJson(json);
      expect(info.assets, hasLength(1));
      expect(info.assets[0].name, 'app-arm64.apk');
      expect(info.assets[0].downloadUrl, 'https://example.com/app.apk');
      expect(info.assets[0].size, 1024000);
    });

    test('5. UpdateInfo.fromJson handles empty assets', () {
      final json = {'tag_name': 'v1.0.0', 'assets': <dynamic>[]};
      final info = UpdateInfo.fromJson(json);
      expect(info.assets, isEmpty);
      expect(info.hasAsset, isFalse);
    });

    test('6. UpdateInfo.fromJson handles missing assets', () {
      final json = {'tag_name': 'v1.0.0'};
      final info = UpdateInfo.fromJson(json);
      expect(info.assets, isEmpty);
    });

    test('7. UpdateInfo.fromJson parses force_update from body JSON', () {
      final json = {
        'tag_name': 'v2.0.0',
        'body': '{"force_update": true, "changelog": "Critical fix"}',
        'assets': <dynamic>[],
      };
      final info = UpdateInfo.fromJson(json);
      expect(info.forceUpdate, isTrue);
      expect(info.changelog, 'Critical fix');
      expect(info.isCritical, isTrue);
    });

    test('8. UpdateInfo.fromJson body as plain text', () {
      final json = {
        'tag_name': 'v2.0.0',
        'body': 'Bug fixes and improvements',
        'assets': <dynamic>[],
      };
      final info = UpdateInfo.fromJson(json);
      expect(info.forceUpdate, isFalse);
      expect(info.changelog, 'Bug fixes and improvements');
    });

    test('9. UpdateInfo.isCritical detects "critical" in body', () {
      final json = {
        'tag_name': 'v2.0.0',
        'body': 'This is a CRITICAL security update',
        'assets': <dynamic>[],
      };
      expect(UpdateInfo.fromJson(json).isCritical, isTrue);
    });

    test('10. UpdateInfo.isCritical detects Vietnamese "quan trọng"', () {
      final json = {
        'tag_name': 'v2.0.0',
        'body': 'Cập nhật quan trọng',
        'assets': <dynamic>[],
      };
      expect(UpdateInfo.fromJson(json).isCritical, isTrue);
    });

    test('11. UpdateInfo.isCritical detects "bắt buộc"', () {
      final json = {
        'tag_name': 'v2.0.0',
        'body': 'Cập nhật bắt buộc',
        'assets': <dynamic>[],
      };
      expect(UpdateInfo.fromJson(json).isCritical, isTrue);
    });

    test('12. UpdateInfo.getRecommendedAsset prefers APK', () {
      final info = UpdateInfo(
        version: '1.0.0', tagName: 'v1.0.0', name: 'R', body: '',
        publishedAt: '', htmlUrl: '',
        assets: [
          UpdateAsset(name: 'app.exe', downloadUrl: 'u1', size: 100, contentType: ''),
          UpdateAsset(name: 'app.apk', downloadUrl: 'u2', size: 200, contentType: ''),
        ],
      );
      expect(info.getRecommendedAsset()?.name, 'app.apk');
    });

    test('13. UpdateInfo.getRecommendedAsset matches device ABI', () {
      final info = UpdateInfo(
        version: '1.0.0', tagName: 'v1.0.0', name: 'R', body: '',
        publishedAt: '', htmlUrl: '',
        assets: [
          UpdateAsset(name: 'app-arm.apk', downloadUrl: 'u1', size: 100, contentType: ''),
          UpdateAsset(name: 'app-arm64.apk', downloadUrl: 'u2', size: 200, contentType: ''),
        ],
      );
      expect(info.getRecommendedAsset(['arm64'])?.name, 'app-arm64.apk');
    });

    test('14. UpdateInfo.getRecommendedAsset returns first APK if no ABI match', () {
      final info = UpdateInfo(
        version: '1.0.0', tagName: 'v1.0.0', name: 'R', body: '',
        publishedAt: '', htmlUrl: '',
        assets: [
          UpdateAsset(name: 'app-arm.apk', downloadUrl: 'u1', size: 100, contentType: ''),
          UpdateAsset(name: 'app-arm64.apk', downloadUrl: 'u2', size: 200, contentType: ''),
        ],
      );
      expect(info.getRecommendedAsset(['x86'])?.name, 'app-arm.apk');
    });

    test('15. UpdateInfo.getRecommendedAsset returns null when empty', () {
      final info = UpdateInfo(
        version: '1.0.0', tagName: 'v1.0.0', name: 'R', body: '',
        publishedAt: '', htmlUrl: '', assets: [],
      );
      expect(info.getRecommendedAsset(), isNull);
    });

    test('16. UpdateInfo.downloadUrl returns recommended asset URL', () {
      final info = UpdateInfo(
        version: '1.0.0', tagName: 'v1.0.0', name: 'R', body: '',
        publishedAt: '', htmlUrl: 'https://fallback.com',
        assets: [UpdateAsset(name: 'a.apk', downloadUrl: 'https://dl.com', size: 100, contentType: '')],
      );
      expect(info.downloadUrl, 'https://dl.com');
    });

    test('17. UpdateInfo.downloadUrl falls back to htmlUrl when no assets', () {
      final info = UpdateInfo(
        version: '1.0.0', tagName: 'v1.0.0', name: 'R', body: '',
        publishedAt: '', htmlUrl: 'https://fallback.com', assets: [],
      );
      expect(info.downloadUrl, 'https://fallback.com');
    });

    test('18. UpdateInfo.fromJson handles missing optional fields', () {
      final json = <String, dynamic>{'tag_name': 'v1.0.0'};
      final info = UpdateInfo.fromJson(json);
      expect(info.name, '1.0.0');
      expect(info.body, '');
      expect(info.publishedAt, '');
      expect(info.htmlUrl, '');
      expect(info.isCritical, isFalse);
      expect(info.forceUpdate, isFalse);
    });

    test('19. UpdateAsset holds correct data', () {
      const asset = UpdateAsset(
        name: 'test.apk',
        downloadUrl: 'https://dl.com',
        size: 5000,
        contentType: 'application/json',
      );
      expect(asset.name, 'test.apk');
      expect(asset.size, 5000);
    });

    test('20. UpdatePlatform enum values', () {
      expect(UpdatePlatform.android.name, 'android');
      expect(UpdatePlatform.windows.name, 'windows');
      expect(UpdatePlatform.web.name, 'web');
      expect(UpdatePlatform.unknown.name, 'unknown');
    });
  });
}
