import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://tsyvpjhpogxmqcpeaowb.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzeXZwamhwb2d4bXFjcGVhb3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY2ODE1MjgsImV4cCI6MjAzMjI1NzUyOH0.30rbkShbpM_h06pZIAw39Ma2SC0thZi9WiV__lhh4Lk';
  static const String bucketName = 'private-schools-accounting';

  static late SupabaseClient _client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    _client = Supabase.instance.client;
  }

  /// اختبار الاتصال بـ Supabase
  static Future<bool> testConnection() async {
    try {
      // محاولة الوصول لقائمة البوكتات للتأكد من الاتصال
      await _client.storage.listBuckets();
      return true;
    } catch (e) {
      throw Exception('فشل في الاتصال بـ Supabase: $e');
    }
  }

  /// اختبار الوصول للبوكت
  static Future<bool> testBucketAccess() async {
    try {
      // محاولة جلب قائمة فارغة للتأكد من الوصول للبوكت
      await _client.storage.from(bucketName).list(path: '');
      return true;
    } catch (e) {
      throw Exception('فشل في الوصول للبوكت: $e');
    }
  }

  /// جلب قائمة الملفات من مجلد المؤسسة
  static Future<List<FileObject>> listFiles(String institutionName) async {
    try {
      final List<FileObject> objects = await _client.storage
          .from(bucketName)
          .list(path: institutionName);

      return objects;
    } catch (e) {
      throw Exception('فشل في جلب قائمة الملفات: $e');
    }
  }

  /// العثور على أحدث ملف backup
  static String findLatestBackupFile(List<FileObject> files) {
    final backupFiles = files
        .where(
          (file) =>
              file.name.startsWith('backup_') && file.name.endsWith('.zip'),
        )
        .toList();

    if (backupFiles.isEmpty) {
      throw Exception('لم يتم العثور على ملفات نسخ احتياطية');
    }

    // ترتيب الملفات بناءً على التاريخ والوقت في الاسم
    backupFiles.sort((a, b) => b.name.compareTo(a.name));

    return backupFiles.first.name;
  }

  /// تنزيل ملف من Supabase Storage
  static Future<Uint8List> downloadFile(
    String institutionName,
    String fileName,
  ) async {
    try {
      final Uint8List fileBytes = await _client.storage
          .from(bucketName)
          .download('$institutionName/$fileName');

      return fileBytes;
    } catch (e) {
      throw Exception('فشل في تنزيل الملف: $e');
    }
  }

  /// تنزيل أحدث نسخة احتياطية
  static Future<Uint8List> downloadLatestBackup(String institutionName) async {
    try {
      // جلب قائمة الملفات
      final files = await listFiles(institutionName);

      // العثور على أحدث ملف
      final latestFile = findLatestBackupFile(files);

      // تنزيل الملف
      return await downloadFile(institutionName, latestFile);
    } catch (e) {
      throw Exception('فشل في تنزيل أحدث نسخة احتياطية: $e');
    }
  }
}
