import 'package:flutter/foundation.dart';

/// Default implementation of [ChangeNotifier]
///
/// Its a controller to send progress downloading file
class DownloaderCallback extends ChangeNotifier {
  double _progress = 0.0;
  double _speedPerSec = 0;

  double get progress => _progress;

  double get speedPerSec => _speedPerSec;
  String get speedPerSecFormatted =>'${double.parse(_speedPerSec.toStringAsFixed(1)) / 1024} KB/s';

  set progress(double value) {
    _progress = value;
    notifyListeners();
  }
  set speedPerSec(double value) {
    _speedPerSec = value;
    notifyListeners();
  }

  DownloadStatus _status = DownloadStatus.undefined;

  DownloadStatus get status => _status;

  set status(DownloadStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  int _total = 0;

  int get total => _total;

  set total(int value) {
    _total = value;
    notifyListeners();
  }

  int _offset = 0;

  int get offset => _offset;

  set offset(int value) {
    _offset = value;
    notifyListeners();
  }
}

enum DownloadStatus {
  undefined,
  running,
  completed,
  deleted,
  paused,
  resume,
  retry,
  canceled,
  failed,
}
