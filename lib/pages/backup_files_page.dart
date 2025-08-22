import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/zip_service.dart';
import '../services/db_service.dart';
import 'home_page.dart';

class BackupFilesPage extends StatefulWidget {
  final String institutionName;

  const BackupFilesPage({super.key, required this.institutionName});

  @override
  State<BackupFilesPage> createState() => _BackupFilesPageState();
}

class _BackupFilesPageState extends State<BackupFilesPage> {
  bool _isLoading = true;
  bool _isDownloading = false;
  String _statusMessage = '';
  List<FileObject> _backupFiles = [];
  String? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'جاري جلب قائمة النسخ الاحتياطية...';
      });

      // جلب قائمة الملفات من مجلد المؤسسة
      final files = await SupabaseService.listFiles(widget.institutionName);

      // تصفية الملفات للحصول على ملفات الـ backup فقط
      final backupFiles = files
          .where(
            (file) =>
                file.name.startsWith('backup_') && file.name.endsWith('.zip'),
          )
          .toList();

      // ترتيب الملفات من الأحدث للأقدم
      backupFiles.sort((a, b) => b.name.compareTo(a.name));

      setState(() {
        _backupFiles = backupFiles;
        _isLoading = false;
        _statusMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'خطأ في جلب قائمة الملفات: ${e.toString()}';
      });
    }
  }

  Future<void> _downloadSelectedFile(String fileName) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _selectedFile = fileName;
      _statusMessage = 'جاري تنزيل الملف: $fileName';
    });

    try {
      // تنزيل الملف المحدد
      final zipBytes = await SupabaseService.downloadFile(
        widget.institutionName,
        fileName,
      );

      setState(() {
        _statusMessage = 'جاري فك ضغط الملف...';
      });

      // فك ضغط الملف واستخراج قاعدة البيانات
      final dbBytes = await ZipService.extractSchoolsDb(zipBytes);

      if (dbBytes == null) {
        throw Exception('لم يتم العثور على ملف قاعدة البيانات');
      }

      setState(() {
        _statusMessage = 'جاري حفظ قاعدة البيانات...';
      });

      // حفظ قاعدة البيانات محلياً
      await DatabaseService.saveDatabase(dbBytes);

      setState(() {
        _statusMessage = '✅ تم تحميل البيانات بنجاح!';
      });

      await Future.delayed(const Duration(seconds: 1));

      // الانتقال إلى الصفحة الرئيسية
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomePage(institutionName: widget.institutionName),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'خطأ في تحميل الملف: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الملف: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
        _selectedFile = null;
      });
    }
  }

  String _formatFileName(String fileName) {
    // استخراج التاريخ والوقت من اسم الملف
    // backup_20250821_124323.zip -> 2025/08/21 - 12:43:23
    final nameWithoutExtension = fileName.replaceAll('.zip', '');
    final parts = nameWithoutExtension.split('_');

    if (parts.length >= 3) {
      final dateStr = parts[1]; // 20250821
      final timeStr = parts[2]; // 124323

      if (dateStr.length == 8 && timeStr.length == 6) {
        final year = dateStr.substring(0, 4);
        final month = dateStr.substring(4, 6);
        final day = dateStr.substring(6, 8);

        final hour = timeStr.substring(0, 2);
        final minute = timeStr.substring(2, 4);
        final second = timeStr.substring(4, 6);

        return '$year/$month/$day - $hour:$minute:$second';
      }
    }

    return fileName; // إذا فشل التحليل، أعرض الاسم الأصلي
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('النسخ الاحتياطية - ${widget.institutionName}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadBackupFiles,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث القائمة',
          ),
        ],
      ),
      body: Column(
        children: [
          // معلومات المؤسسة
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'المؤسسة: ${widget.institutionName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'المسار: backups/${widget.institutionName}/',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'النسخ الاحتياطية المتاحة: ${_backupFiles.length}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // رسالة الحالة
          if (_statusMessage.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _statusMessage.contains('خطأ')
                    ? Colors.red.withOpacity(0.1)
                    : _statusMessage.contains('✅')
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _statusMessage.contains('خطأ')
                      ? Colors.red.withOpacity(0.3)
                      : _statusMessage.contains('✅')
                      ? Colors.green.withOpacity(0.3)
                      : Colors.blue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _statusMessage.contains('خطأ')
                        ? Icons.error
                        : _statusMessage.contains('✅')
                        ? Icons.check_circle
                        : Icons.info,
                    color: _statusMessage.contains('خطأ')
                        ? Colors.red
                        : _statusMessage.contains('✅')
                        ? Colors.green
                        : Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusMessage.contains('خطأ')
                            ? Colors.red
                            : _statusMessage.contains('✅')
                            ? Colors.green
                            : Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // قائمة الملفات
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('جاري تحميل قائمة النسخ الاحتياطية...'),
                      ],
                    ),
                  )
                : _backupFiles.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد نسخ احتياطية متاحة',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _backupFiles.length,
                    itemBuilder: (context, index) {
                      final file = _backupFiles[index];
                      final isDownloading =
                          _isDownloading && _selectedFile == file.name;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.archive,
                            color: isDownloading ? Colors.orange : Colors.blue,
                          ),
                          title: Text(
                            _formatFileName(file.name),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('الملف: ${file.name}'),
                              if (file.metadata != null &&
                                  file.metadata!['size'] != null)
                                Text(
                                  'الحجم: ${(file.metadata!['size'] / 1024 / 1024).toStringAsFixed(2)} MB',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: isDownloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : IconButton(
                                  onPressed: _isDownloading
                                      ? null
                                      : () => _downloadSelectedFile(file.name),
                                  icon: const Icon(Icons.download),
                                  tooltip: 'تحميل هذا الملف',
                                ),
                          onTap: _isDownloading
                              ? null
                              : () => _downloadSelectedFile(file.name),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
