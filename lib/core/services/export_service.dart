import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  static Future<File?> saveReportToFile(
    String reportText,
    String fileName,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(reportText);
      return file;
    } catch (e) {
      return null;
    }
  }

  static Future<void> shareReport(String reportText, String fileName) async {
    try {
      // shortcut: share text only, file attachment needs platform-specific handling
      await Share.share(reportText, subject: 'Laporan BAGASSPACXE');
    } catch (e) {
      rethrow;
    }
  }

  static Future<String?> getReportPath(String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
