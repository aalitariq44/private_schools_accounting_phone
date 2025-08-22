import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseService {
  static Database? _database;
  static String? _dbPath;

  /// حفظ ملف قاعدة البيانات محلياً
  static Future<String> saveDatabase(Uint8List dbBytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = join(directory.path, 'schools.db');
      
      final file = File(dbPath);
      await file.writeAsBytes(dbBytes);
      
      _dbPath = dbPath;
      return dbPath;
    } catch (e) {
      throw Exception('فشل في حفظ قاعدة البيانات: $e');
    }
  }

  /// فتح قاعدة البيانات
  static Future<Database> openDatabase() async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    if (_dbPath == null) {
      throw Exception('لم يتم تحديد مسار قاعدة البيانات');
    }

    try {
      _database = await openReadOnlyDatabase(_dbPath!);
      return _database!;
    } catch (e) {
      throw Exception('فشل في فتح قاعدة البيانات: $e');
    }
  }

  /// إغلاق قاعدة البيانات
  static Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  /// التحقق من وجود قاعدة البيانات محلياً
  static Future<bool> isDatabaseExists() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dbPath = join(directory.path, 'schools.db');
      final file = File(dbPath);
      
      if (await file.exists()) {
        _dbPath = dbPath;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// جلب جميع المدارس
  static Future<List<Map<String, dynamic>>> getSchools() async {
    try {
      final db = await openDatabase();
      return await db.query('Schools');
    } catch (e) {
      throw Exception('فشل في جلب بيانات المدارس: $e');
    }
  }

  /// جلب جميع الطلاب
  static Future<List<Map<String, dynamic>>> getStudents() async {
    try {
      final db = await openDatabase();
      return await db.query('Students');
    } catch (e) {
      throw Exception('فشل في جلب بيانات الطلاب: $e');
    }
  }

  /// جلب جميع الأقساط
  static Future<List<Map<String, dynamic>>> getPayments() async {
    try {
      final db = await openDatabase();
      return await db.query('Payments');
    } catch (e) {
      throw Exception('فشل في جلب بيانات الأقساط: $e');
    }
  }

  /// جلب طلاب مدرسة معينة
  static Future<List<Map<String, dynamic>>> getStudentsBySchool(int schoolId) async {
    try {
      final db = await openDatabase();
      return await db.query(
        'Students',
        where: 'school_id = ?',
        whereArgs: [schoolId],
      );
    } catch (e) {
      throw Exception('فشل في جلب طلاب المدرسة: $e');
    }
  }

  /// جلب أقساط طالب معين
  static Future<List<Map<String, dynamic>>> getPaymentsByStudent(int studentId) async {
    try {
      final db = await openDatabase();
      return await db.query(
        'Payments',
        where: 'student_id = ?',
        whereArgs: [studentId],
      );
    } catch (e) {
      throw Exception('فشل في جلب أقساط الطالب: $e');
    }
  }

  /// جلب أسماء الجداول الموجودة في قاعدة البيانات
  static Future<List<String>> getTableNames() async {
    try {
      final db = await openDatabase();
      final result = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
      );
      
      return result
          .map((table) => table['name'] as String)
          .where((name) => !name.startsWith('sqlite_'))
          .toList();
    } catch (e) {
      throw Exception('فشل في جلب أسماء الجداول: $e');
    }
  }

  /// جلب معلومات الأعمدة لجدول معين
  static Future<List<Map<String, dynamic>>> getTableInfo(String tableName) async {
    try {
      final db = await openDatabase();
      return await db.rawQuery('PRAGMA table_info($tableName)');
    } catch (e) {
      throw Exception('فشل في جلب معلومات الجدول: $e');
    }
  }
}
