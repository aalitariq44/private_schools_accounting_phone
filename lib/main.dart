import 'package:flutter/material.dart';
import 'services/supabase_service.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة خدمة Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    print('خطأ في تهيئة Supabase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المدرسة الإلكترونية - عارض البيانات',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        // دعم اللغة العربية
        fontFamily: 'Arial',
      ),
      // جعل التطبيق يدعم الاتجاه من اليمين لليسار للغة العربية
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
