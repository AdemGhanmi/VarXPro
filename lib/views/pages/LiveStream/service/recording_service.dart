import 'dart:io';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class RecordingService {
  Future<String> getRecordingFilePath(String channelName) async {
    Directory publicDir;
    if (Platform.isAndroid) {
      publicDir = Directory('/storage/emulated/0/Movies');
      if (!await publicDir.exists()) {
        await publicDir.create(recursive: true);
      }
    } else if (Platform.isIOS) {
      publicDir = await getApplicationDocumentsDirectory();
    } else {
      publicDir = await getTemporaryDirectory();
    }

    final fileName =
        'Recording_${channelName}_${DateTime.now().millisecondsSinceEpoch}.mp4';
    return p.join(publicDir.path, fileName);
  }

  Future<void> startRecording(String channelName, String title, String message) async {
    final filePath = await getRecordingFilePath(channelName);
    await FlutterScreenRecording.startRecordScreen(
      "Recording $channelName",
      titleNotification: title,
      messageNotification: message,
    );
    // filePath متاعك موجود لو تحب تحفظو بعد
  }

  Future<String?> stopRecording() async {
    return await FlutterScreenRecording.stopRecordScreen; // <- لازم ()
  }
}
