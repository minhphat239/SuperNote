import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/update_info.dart';
import '../services/update_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UpdateInfo? _updateInfo;
  bool _isChecking = true;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  bool _updateSuccess = false;
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final version = await UpdateService.getCurrentVersion();
    setState(() => _currentVersion = version);
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _isChecking = true;
      _updateSuccess = false;
    });

    final update = await UpdateService.checkForUpdate();

    setState(() {
      _updateInfo = update;
      _isChecking = false;
    });
  }

  Future<void> _downloadUpdate() async {
    if (_updateInfo == null || !_updateInfo!.hasDownloadUrl) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    final success = await UpdateService.downloadUpdate(
      _updateInfo!.downloadUrl,
      _updateInfo!.assetName,
      (progress) {
        setState(() => _downloadProgress = progress);
      },
    );

    setState(() {
      _isDownloading = false;
      _updateSuccess = success;
      if (success) _updateInfo = null;
    });
  }

  Future<void> _openReleasePage() async {
    final url = Uri.parse(UpdateService.getReleaseUrl());
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SuperNote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkForUpdate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SuperNote',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version: $_currentVersion',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildUpdateSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateSection() {
    if (_isChecking) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Checking for updates...'),
            ],
          ),
        ),
      );
    }

    if (_updateSuccess) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Successfully Updated!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _checkForUpdate,
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_updateInfo != null) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.system_update, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New version available!',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Version ${_updateInfo!.version}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_updateInfo!.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _updateInfo!.releaseNotes,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_isDownloading) ...[
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(value: _downloadProgress),
                    ),
                    const SizedBox(width: 8),
                    Text('${(_downloadProgress * 100).toInt()}%'),
                  ] else ...[
                    if (_updateInfo!.hasDownloadUrl)
                      ElevatedButton.icon(
                        onPressed: _downloadUpdate,
                        icon: const Icon(Icons.download),
                        label: const Text('Update'),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _openReleasePage,
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Open in Browser'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green),
            const SizedBox(width: 16),
            const Text('You are using the latest version'),
            const Spacer(),
            TextButton.icon(
              onPressed: _openReleasePage,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Releases'),
            ),
          ],
        ),
      ),
    );
  }
}
