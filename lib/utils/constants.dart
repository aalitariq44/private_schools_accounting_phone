class AppConstants {
  // بيانات Supabase
  static const String supabaseUrl = 'https://tsyvpjhpogxmqcpeaowb.supabase.co';
  static const String supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzeXZwamhwb2d4bXFjcGVhb3diIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTY2ODE1MjgsImV4cCI6MjAzMjI1NzUyOH0.30rbkShbpM_h06pZIAw39Ma2SC0thZi9WiV__lhh4Lk';
  static const String bucketName = 'private-schools-accounting';

  // أسماء الملفات والمجلدات
  static const String dbFileName = 'schools.db';
  static const String backupPrefix = 'backup_';
  static const String backupExtension = '.zip';

  // النصوص
  static const String appTitle = 'المدرسة الإلكترونية - عارض البيانات';
  static const String welcomeMessage =
      'مرحباً بك في نظام عرض بيانات المدارس الخاصة';

  // رسائل الخطأ
  static const String errorNoInstitution = 'يرجى إدخال اسم المؤسسة';
  static const String errorNoBackupFiles =
      'لم يتم العثور على ملفات نسخ احتياطية';
  static const String errorNoDatabaseFile =
      'لم يتم العثور على ملف قاعدة البيانات';
  static const String errorConnectionFailed = 'فشل في الاتصال بالخادم';
  static const String errorDownloadFailed = 'فشل في تنزيل الملف';
  static const String errorExtractFailed = 'فشل في فك ضغط الملف';
  static const String errorDatabaseSaveFailed = 'فشل في حفظ قاعدة البيانات';
  static const String errorDatabaseOpenFailed = 'فشل في فتح قاعدة البيانات';

  // رسائل الحالة
  static const String statusConnecting = 'جاري الاتصال بالخادم...';
  static const String statusDownloading = 'جاري تنزيل أحدث نسخة احتياطية...';
  static const String statusExtracting = 'جاري فك ضغط الملف...';
  static const String statusSaving = 'جاري حفظ قاعدة البيانات...';
  static const String statusSuccess = 'تم تحميل البيانات بنجاح!';
  static const String statusLoadingData = 'جاري تحميل البيانات...';

  // أسماء الجداول (بالعربية والإنجليزية)
  static const Map<String, String> tableTranslations = {
    'schools': 'المدارس',
    'Schools': 'المدارس',
    'students': 'الطلاب',
    'Students': 'الطلاب',
    'payments': 'الأقساط',
    'Payments': 'الأقساط',
  };

  // ترجمة أسماء الأعمدة
  static const Map<String, String> columnTranslations = {
    // المعرفات
    'id': 'المعرف',
    'student_id': 'رقم الطالب',
    'school_id': 'رقم المدرسة',

    // الأسماء
    'name': 'الاسم',
    'student_name': 'اسم الطالب',
    'school_name': 'اسم المدرسة',
    'first_name': 'الاسم الأول',
    'last_name': 'اسم العائلة',
    'parent_name': 'اسم ولي الأمر',

    // بيانات الاتصال
    'address': 'العنوان',
    'phone': 'الهاتف',
    'parent_phone': 'هاتف ولي الأمر',
    'email': 'البريد الإلكتروني',

    // التواريخ
    'birth_date': 'تاريخ الميلاد',
    'enrollment_date': 'تاريخ التسجيل',
    'payment_date': 'تاريخ الدفع',
    'due_date': 'تاريخ الاستحقاق',
    'date': 'التاريخ',
    'established_date': 'تاريخ التأسيس',
    'created_at': 'تاريخ الإنشاء',
    'updated_at': 'تاريخ التحديث',

    // بيانات تعليمية
    'class': 'الصف',
    'grade': 'المرحلة',
    'level': 'المرحلة',
    'type': 'النوع',
    'director': 'المدير',

    // البيانات المالية
    'amount': 'المبلغ',
    'status': 'الحالة',
    'method': 'طريقة الدفع',
    'reference': 'المرجع',

    // معلومات إضافية
    'gender': 'الجنس',
    'description': 'الوصف',
    'notes': 'ملاحظات',
  };

  // ترجمة حالات الأقساط
  static const Map<String, String> paymentStatusTranslations = {
    'paid': 'مدفوع',
    'pending': 'معلق',
    'overdue': 'متأخر',
    'cancelled': 'ملغي',
    'refunded': 'مسترد',
  };

  // الألوان
  static const Map<String, int> statusColors = {
    'paid': 0xFF4CAF50, // أخضر
    'pending': 0xFFFF9800, // برتقالي
    'overdue': 0xFFF44336, // أحمر
    'cancelled': 0xFF9E9E9E, // رمادي
    'refunded': 0xFF2196F3, // أزرق
  };
}

class AppHelpers {
  /// ترجمة اسم العمود
  static String translateColumnName(String columnName) {
    return AppConstants.columnTranslations[columnName.toLowerCase()] ??
        columnName;
  }

  /// ترجمة اسم الجدول
  static String translateTableName(String tableName) {
    return AppConstants.tableTranslations[tableName] ?? tableName;
  }

  /// ترجمة حالة القسط
  static String translatePaymentStatus(String status) {
    return AppConstants.paymentStatusTranslations[status.toLowerCase()] ??
        status;
  }

  /// الحصول على لون الحالة
  static int getStatusColor(String status) {
    return AppConstants.statusColors[status.toLowerCase()] ?? 0xFF9E9E9E;
  }

  /// تنسيق المبلغ المالي
  static String formatAmount(dynamic amount) {
    if (amount == null) return '0.00';

    final double value = double.tryParse(amount.toString()) ?? 0.0;
    return value.toStringAsFixed(2);
  }

  /// تنسيق التاريخ
  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'غير محدد';

    try {
      final DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString; // إرجاع النص الأصلي إذا فشل التحويل
    }
  }

  /// استخراج الأحرف الأولى من الاسم
  static String getInitials(String? name) {
    if (name == null || name.isEmpty) return 'غ';

    final words = name.trim().split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    } else if (words.isNotEmpty) {
      final firstWord = words[0];
      return firstWord.length >= 2 ? firstWord.substring(0, 2) : firstWord;
    }
    return 'غ';
  }

  /// التحقق من صحة اسم المؤسسة
  static bool isValidInstitutionName(String name) {
    return name.trim().isNotEmpty &&
        name.trim().length >= 2 &&
        RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(name.trim());
  }

  /// إنشاء نص البحث القابل للبحث فيه
  static String createSearchableText(Map<String, dynamic> data) {
    return data.values
        .where((value) => value != null)
        .map((value) => value.toString().toLowerCase())
        .join(' ');
  }
}
