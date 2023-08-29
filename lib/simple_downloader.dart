export 'src/simple_downloader_task.dart';
export 'src/simple_downloader_callback.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import 'src/simple_downloader_callback.dart';
import 'src/simple_downloader_method.dart';
import 'src/simple_downloader_task.dart';
import 'src/simple_downloader_platform_interface.dart';

/// Use instances of [SimpleDownloaded] to start this plugin
///
class SimpleDownloader {
  static SimpleDownloader? _instance;
  static StreamSubscription? _subscription;

  final Client _client;
  final DownloaderTask _task;
  final DownloaderCallback _callback;

  DownloaderCallback get callback => _callback;

  late DownloaderMethod _method;
  SimpleDownloader._internal(this._client, this._task, this._callback) {
    _method =
        DownloaderMethod(client: _client, task: _task, callback: _callback);
  }

  /// create new instance of Simple downloader.
  ///
  static SimpleDownloader init({required DownloaderTask task}) {
    if (_instance == null) {
      final Client client = Client();
      final callback = DownloaderCallback();
      return SimpleDownloader._internal(client, task, callback);
    }

    return _instance!;
  }

  /// disposing callback, http client & stream subsciption
  /// to release the memory allocated.
  void dispose() {
    _callback.dispose();
    _client.close();
    _subscription?.cancel();
  }

  /// start download file.
  Future<void> download() async {
    if (_callback.status != DownloadStatus.running) {
      _subscription = await _method.start();
    }
    // _method.start();
  }

  /// pause downloading file.
  Future<void> pause() async {
    if (_callback.status == DownloadStatus.running) {
      _callback.status = DownloadStatus.paused;
      _subscription?.pause();
    }
  }

  /// resume downloading file.
  Future<void> resume() async {
    if (_callback.status == DownloadStatus.paused) {
      _callback.status = DownloadStatus.resume;
      _subscription?.resume();
    }
  }

  /// cancel downloading file.
  Future<void> cancel() async {
    _callback.status = DownloadStatus.canceled;
    _subscription?.cancel();
  }

  /// retry downloading file.
  /// this function can be run if status downloading file is failed or canceled.
  Future<void> retry() async {
    if (_callback.status == DownloadStatus.failed ||
        _callback.status == DownloadStatus.canceled) {
      _subscription = await _method.start(resume: true);
    }
  }

  /// restart downloading file.
  Future<void> restart() async {
    if (_callback.status == DownloadStatus.failed ||
        _callback.status == DownloadStatus.canceled) {
      download();
    }
  }

  /// delete downloaded file.
  Future<bool?> delete() async {
    try {
      return await _method.deleteFiles();
    } catch (e) {
      debugPrint("$e");
      return Future.value(false);
    }
  }
}
