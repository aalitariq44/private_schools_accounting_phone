import 'dart:typed_data';
import 'package:archive/archive_io.dart';

class ZipService {
  /// فك ضغط ملف ZIP واستخراج schools.db
  static Future<Uint8List?> extractSchoolsDb(Uint8List zipBytes) async {
    try {
      // فك ضغط الملف
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // البحث عن ملف schools.db
      for (final file in archive) {
        if (file.name == 'schools.db' && !file.isFile) {
          continue;
        }

        if (file.name == 'schools.db') {
          // استخراج محتوى الملف
          final content = file.content as List<int>;
          return Uint8List.fromList(content);
        }
      }

      throw Exception('لم يتم العثور على ملف schools.db في الأرشيف');
    } catch (e) {
      throw Exception('فشل في فك ضغط الملف: $e');
    }
  }

  /// التحقق من أن الملف هو ZIP صالح
  static bool isValidZip(Uint8List bytes) {
    try {
      ZipDecoder().decodeBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// جلب قائمة الملفات داخل الأرشيف
  static Future<List<String>> listFilesInZip(Uint8List zipBytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(zipBytes);
      return archive.map((file) => file.name).toList();
    } catch (e) {
      throw Exception('فشل في قراءة محتويات الأرشيف: $e');
    }
  }
}
