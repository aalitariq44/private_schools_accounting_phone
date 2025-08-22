import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/zip_service.dart';
import '../services/db_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _institutionController = TextEditingController();
  bool _isLoading = false;
  String _statusMessage = '';

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

  Future<void> _downloadLatestBackup() async {
    if (_institutionController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم المؤسسة');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final institutionName = _institutionController.text.trim();
      
      _setStatus('جاري الاتصال بالخادم...');
      
      // تنزيل أحدث نسخة احتياطية
      _setStatus('جاري تنزيل أحدث نسخة احتياطية...');
      final zipBytes = await SupabaseService.downloadLatestBackup(institutionName);
      
      _setStatus('جاري فك ضغط الملف...');
      
      // فك ضغط الملف واستخراج قاعدة البيانات
      final dbBytes = await ZipService.extractSchoolsDb(zipBytes);
      
      if (dbBytes == null) {
        throw Exception('لم يتم العثور على ملف قاعدة البيانات');
      }
      
      _setStatus('جاري حفظ قاعدة البيانات...');
      
      // حفظ قاعدة البيانات محلياً
      await DatabaseService.saveDatabase(dbBytes);
      
      _setStatus('تم تحميل البيانات بنجاح!');
      
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
      _statusMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _checkExistingDatabase() async {
    if (await DatabaseService.isDatabaseExists()) {
      final shouldUseExisting = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('قاعدة بيانات موجودة'),
          content: const Text('توجد قاعدة بيانات محفوظة مسبقاً. هل تريد استخدامها أم تحميل نسخة جديدة؟'),
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
            builder: (context) => HomePage(institutionName: _institutionController.text.trim()),
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            
            const Text(
              'مرحباً بك في نظام عرض بيانات المدارس الخاصة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(
                labelText: 'اسم المؤسسة',
                hintText: 'أدخل اسم المؤسسة (مثال: sumer)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              textAlign: TextAlign.center,
              enabled: !_isLoading,
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _downloadLatestBackup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
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
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('جاري التحميل...'),
                        ],
                      )
                    : const Text(
                        'تحميل النسخة الأخيرة',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _checkExistingDatabase,
                child: const Text(
                  'التحقق من وجود قاعدة بيانات محفوظة',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(color: Colors.blue),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
