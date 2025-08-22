import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/zip_service.dart';
import '../services/db_service.dart';
import 'home_page.dart';
import 'backup_files_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _institutionController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _supabaseConnected = false;
  bool _bucketAccessible = false;

  @override
  void dispose() {
    _institutionController.dispose();
    super.dispose();
  }

  void _setStatus(String message) {
    setState(() {
      _statusMessage = message;
    });
  }

  Color _getStatusColor() {
    if (_statusMessage.contains('✅')) {
      return Colors.green;
    } else if (_statusMessage.contains('❌')) {
      return Colors.red;
    } else if (_statusMessage.contains('خطأ') ||
        _statusMessage.contains('فشل')) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    if (_statusMessage.contains('✅')) {
      return Icons.check_circle;
    } else if (_statusMessage.contains('❌')) {
      return Icons.error;
    } else if (_statusMessage.contains('خطأ') ||
        _statusMessage.contains('فشل')) {
      return Icons.error_outline;
    } else {
      return Icons.info;
    }
  }

  Future<void> _browseBackupFiles() async {
    if (_institutionController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم المؤسسة');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _supabaseConnected = false;
      _bucketAccessible = false;
    });

    try {
      final institutionName = _institutionController.text.trim();

      // اختبار الاتصال بـ Supabase
      _setStatus('جاري اختبار الاتصال بـ Supabase...');
      try {
        await SupabaseService.testConnection();
        setState(() {
          _supabaseConnected = true;
        });
        _setStatus('✅ نجح الاتصال بـ Supabase');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        setState(() {
          _supabaseConnected = false;
        });
        _setStatus('❌ فشل الاتصال بـ Supabase');
        await Future.delayed(const Duration(seconds: 1));
        throw e;
      }

      // اختبار الوصول للبوكت
      _setStatus('جاري اختبار الوصول للبوكت...');
      try {
        await SupabaseService.testBucketAccess();
        setState(() {
          _bucketAccessible = true;
        });
        _setStatus('✅ نجح الوصول للبوكت');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        setState(() {
          _bucketAccessible = false;
        });
        _setStatus('❌ فشل الوصول للبوكت');
        await Future.delayed(const Duration(seconds: 1));
        throw e;
      }

      // التحقق من وجود ملفات في المجلد
      _setStatus('جاري التحقق من وجود ملفات النسخ الاحتياطية...');
      try {
        final files = await SupabaseService.listFiles(institutionName);
        final backupFiles = files
            .where(
              (file) =>
                  file.name.startsWith('backup_') && file.name.endsWith('.zip'),
            )
            .toList();

        if (backupFiles.isEmpty) {
          throw Exception(
            'لم يتم العثور على ملفات نسخ احتياطية في مجلد "$institutionName"',
          );
        }

        _setStatus('✅ تم العثور على ${backupFiles.length} ملف نسخ احتياطية');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        _setStatus('❌ ${e.toString()}');
        await Future.delayed(const Duration(seconds: 2));
        throw e;
      }

      // الانتقال إلى صفحة تصفح الملفات
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BackupFilesPage(institutionName: institutionName),
          ),
        );
      }
    } catch (e) {
      _showError('خطأ في الوصول للملفات: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadLatestBackup() async {
    if (_institutionController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم المؤسسة');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _supabaseConnected = false;
      _bucketAccessible = false;
    });

    try {
      final institutionName = _institutionController.text.trim();

      // اختبار الاتصال بـ Supabase
      _setStatus('جاري اختبار الاتصال بـ Supabase...');
      try {
        await SupabaseService.testConnection();
        setState(() {
          _supabaseConnected = true;
        });
        _setStatus('✅ نجح الاتصال بـ Supabase');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        setState(() {
          _supabaseConnected = false;
        });
        _setStatus('❌ فشل الاتصال بـ Supabase');
        await Future.delayed(const Duration(seconds: 1));
        throw e;
      }

      // اختبار الوصول للبوكت
      _setStatus('جاري اختبار الوصول للبوكت...');
      try {
        await SupabaseService.testBucketAccess();
        setState(() {
          _bucketAccessible = true;
        });
        _setStatus('✅ نجح الوصول للبوكت');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        setState(() {
          _bucketAccessible = false;
        });
        _setStatus('❌ فشل الوصول للبوكت');
        await Future.delayed(const Duration(seconds: 1));
        throw e;
      }

      // تنزيل أحدث نسخة احتياطية
      _setStatus('جاري تنزيل أحدث نسخة احتياطية...');
      final zipBytes = await SupabaseService.downloadLatestBackup(
        institutionName,
      );

      _setStatus('جاري فك ضغط الملف...');

      // فك ضغط الملف واستخراج قاعدة البيانات
      final dbBytes = await ZipService.extractSchoolsDb(zipBytes);

      if (dbBytes == null) {
        throw Exception('لم يتم العثور على ملف قاعدة البيانات');
      }

      _setStatus('جاري حفظ قاعدة البيانات...');

      // حفظ قاعدة البيانات محلياً
      await DatabaseService.saveDatabase(dbBytes);

      _setStatus('✅ تم تحميل البيانات بنجاح!');
      await Future.delayed(const Duration(seconds: 1));

      // الانتقال إلى الصفحة الرئيسية
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(institutionName: institutionName),
          ),
        );
      }
    } catch (e) {
      _showError('خطأ في التحميل: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _statusMessage = '❌ ' + message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _checkExistingDatabase() async {
    if (await DatabaseService.isDatabaseExists()) {
      final shouldUseExisting = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('قاعدة بيانات موجودة'),
          content: const Text(
            'توجد قاعدة بيانات محفوظة مسبقاً. هل تريد استخدامها أم تحميل نسخة جديدة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تحميل جديد'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('استخدام الموجود'),
            ),
          ],
        ),
      );

      if (shouldUseExisting == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(institutionName: _institutionController.text.trim()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدرسة الإلكترونية - عارض البيانات'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight - 48, // Accounting for padding
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    const Icon(Icons.school, size: 100, color: Colors.blue),

                    const SizedBox(height: 32),

                    const Text(
                      'مرحباً بك في نظام عرض بيانات المدارس الخاصة',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _institutionController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المؤسسة',
                          hintText: 'أدخل اسم المؤسسة (مثال: sumer)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          prefixIcon: Icon(Icons.business),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        enabled: !_isLoading,
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _browseBackupFiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('جاري التحقق...'),
                                ],
                              )
                            : const Text(
                                'تصفح النسخ الاحتياطية',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _downloadLatestBackup,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.green, width: 2),
                        ),
                        child: const Text(
                          'تحميل آخر نسخة مباشرة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _checkExistingDatabase,
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(
                            color: Colors.orange,
                            width: 2,
                          ),
                        ),
                        child: const Text(
                          'التحقق من وجود قاعدة بيانات محفوظة',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // عرض حالة الاتصالات
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'حالة الاتصالات:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _supabaseConnected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _supabaseConnected
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الاتصال بـ Supabase',
                                style: TextStyle(
                                  color: _supabaseConnected
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _bucketAccessible
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _bucketAccessible
                                    ? Colors.green
                                    : Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'الوصول للبوكت',
                                style: TextStyle(
                                  color: _bucketAccessible
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    if (_statusMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor().withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(),
                              color: _getStatusColor(),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _getStatusColor(),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
