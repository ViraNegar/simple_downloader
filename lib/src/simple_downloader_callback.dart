import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:http/http.dart';
import 'package:path/path.dart' as p;

import 'simple_downloader_callback.dart';
import 'simple_downloader_task.dart';

/// Controller to handle process downloading file
class DownloaderMethod {
  final Client client;
  final DownloaderTask task;
  final DownloaderCallback callback;

  DownloaderMethod({
    required this.client,
    required this.task,
    required this.callback,
  });

  Future<StreamSubscription> start({bool resume = false}) async {
    late StreamSubscription subscription;
    int total = 0;
    int offset = 0;

    try {
      callback.status = DownloadStatus.running;
      Client httpClient = client;
      Request request = Request('GET', Uri.parse(task.url!));
      if(task.headers != null){
        request.headers.addAll(task.headers!);
      }
      File file;

      /// if params resume value is true
      /// offset value takes from length of temp files
      /// and try downloading files using range content header
      if (resume) {
        final path = p.join(task.downloadPath!, task.fileName!);
        file = File('$path.tmp');
        offset = await file.length();
        request.headers.addAll({'range': 'bytes=$offset-'});
      } else {
        // Open file
        file = await _createFile();
      }

      StreamedResponse response = await httpClient.send(request);
      if (resume) {
        total = int.parse(
            response.headers[HttpHeaders.contentRangeHeader]!.split("/").last);
      } else {
      }


      final stopwatch = Stopwatch()..start();
      int totalByteInSecs = 0;

      Timer.periodic(Duration(seconds: 1), (timer) {
        totalByteInSecs = 0;
        stopwatch.reset();
      });

      final reader = ChunkedStreamReader(response.stream);
      subscription = _streamData(reader).listen((buffer) async {
        // accumulate length downloaded
        offset += buffer.length;
        total = response.contentLength ?? offset;
        totalByteInSecs += buffer.length;

        final elapsedSeconds = stopwatch.elapsedMilliseconds / 1000;
        final downloadSpeed = totalByteInSecs / elapsedSeconds; // bytes per second

        // Write buffer to disk
        file.writeAsBytesSync(buffer, mode: FileMode.writeOnlyAppend);

        // callback download progress
        callback
          ..offset = offset
          ..total = total
          ..speedPerSec = downloadSpeed
          ..progress = (offset / total) * 100;
      }, onDone: () async {
        // rename file
        final path = p.join(task.downloadPath!, task.fileName!);
        await file.rename(path);

        // callback download progress
        callback.status = DownloadStatus.completed;
      }, onError: (error) {
        subscription.cancel();

        // callback download progress
        callback.status = DownloadStatus.failed;
      });

      return subscription;
    } catch (e,stackTrace) {
      callback.status = DownloadStatus.failed;
      rethrow;
    }
  }

  Stream<Uint8List> _streamData(ChunkedStreamReader<int> reader) async* {
    // set the chunk size
    int chunkSize = (task.bufferSize * 1024);
    Uint8List buffer;
    do {
      buffer = await reader.readBytes(chunkSize);
      yield buffer;
    } while (buffer.length == chunkSize);
  }

  Future<bool> deleteFiles() async {
    try {
      final path = p.join(task.downloadPath!, task.fileName!);
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }

      /// callback download progress
      callback
        ..progress = 0.0
        ..status = DownloadStatus.deleted;

      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  }

  Future<File> _createFile() async {
    try {
      // checking file .tmp or download file is exists or not
      // if file exists, file delete first before create.
      final path = p.join(task.downloadPath!, task.fileName!);
      final tempFile = File('$path.tmp');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      await tempFile.create(recursive: true);

      return Future.value(tempFile);
    } catch (e) {
      rethrow;
    }
  }
}
