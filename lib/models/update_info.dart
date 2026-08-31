class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;
  final String assetName;

  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.assetName,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>? ?? [];
    String downloadUrl = '';
    String assetName = '';

    for (final asset in assets) {
      if (asset['name'].toString().endsWith('.zip') ||
          asset['name'].toString().endsWith('.tar.gz') ||
          asset['name'].toString().endsWith('_linux') ||
          !asset['name'].toString().contains('.')) {
        downloadUrl = asset['browser_download_url'] ?? '';
        assetName = asset['name'] ?? '';
        break;
      }
    }

    if (assets.isNotEmpty && downloadUrl.isEmpty) {
      downloadUrl = assets[0]['browser_download_url'] ?? '';
      assetName = assets[0]['name'] ?? '';
    }

    return UpdateInfo(
      version: (json['tag_name'] ?? '').toString().replaceAll('v', ''),
      releaseNotes: json['body'] ?? 'No release notes',
      downloadUrl: downloadUrl,
      assetName: assetName,
    );
  }

  bool get hasDownloadUrl => downloadUrl.isNotEmpty;
}
