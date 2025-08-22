import 'package:flutter/material.dart';
import '../services/db_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final students = await DatabaseService.getStudents();
      
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل بيانات الطلاب: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _students;
    }
    
    return _students.where((student) {
      final name = student['name']?.toString().toLowerCase() ?? '';
      final studentName = student['student_name']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return name.contains(query) || studentName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطلاب'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadStudents,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('جاري تحميل بيانات الطلاب...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStudents,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _students.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا يوجد طلاب مسجلون',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // شريط البحث والإحصائيات
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // شريط البحث
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'البحث عن طالب',
                                  hintText: 'أدخل اسم الطالب...',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // الإحصائيات
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(Icons.people, color: Colors.green),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_students.length}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const Text('إجمالي الطلاب'),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(Icons.search, color: Colors.blue),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_filteredStudents.length}',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                        const Text('نتائج البحث'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // قائمة الطلاب
                        Expanded(
                          child: _filteredStudents.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'لا توجد نتائج للبحث',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildStudentsList(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildStudentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Text(
                _getStudentInitials(student),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student['name']?.toString() ?? 
              student['student_name']?.toString() ?? 
              'طالب غير محدد',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الرقم التعريفي: ${student['id'] ?? 'غير محدد'}'),
                if (student['school_id'] != null)
                  Text('رقم المدرسة: ${student['school_id']}'),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...student.entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '${_translateColumnName(entry.key)}:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(entry.value?.toString() ?? 'غير محدد'),
                                  ),
                                ],
                              ),
                            )),
                    
                    const Divider(),
                    
                    // زر عرض الأقساط
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showStudentPayments(student),
                        icon: const Icon(Icons.payment),
                        label: const Text('عرض الأقساط'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStudentInitials(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 
                 student['student_name']?.toString() ?? 
                 'طالب';
    
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}';
    } else if (words.isNotEmpty) {
      return words[0].substring(0, words[0].length >= 2 ? 2 : 1);
    }
    return 'ط';
  }

  Future<void> _showStudentPayments(Map<String, dynamic> student) async {
    try {
      final studentId = student['id'];
      if (studentId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن تحديد معرف الطالب'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final payments = await DatabaseService.getPaymentsByStudent(studentId);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('أقساط الطالب: ${student['name'] ?? student['student_name'] ?? 'غير محدد'}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: payments.isEmpty
                ? const Center(
                    child: Text('لا توجد أقساط مسجلة لهذا الطالب'),
                  )
                : ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.payment, color: Colors.orange),
                          title: Text('المبلغ: ${payment['amount'] ?? 'غير محدد'}'),
                          subtitle: Text('التاريخ: ${payment['payment_date'] ?? payment['date'] ?? 'غير محدد'}'),
                          trailing: Text(payment['status']?.toString() ?? 'غير محدد'),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل الأقساط: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _translateColumnName(String columnName) {
    final translations = {
      'id': 'المعرف',
      'name': 'الاسم',
      'student_name': 'اسم الطالب',
      'first_name': 'الاسم الأول',
      'last_name': 'اسم العائلة',
      'school_id': 'رقم المدرسة',
      'class': 'الصف',
      'grade': 'المرحلة',
      'birth_date': 'تاريخ الميلاد',
      'gender': 'الجنس',
      'address': 'العنوان',
      'phone': 'الهاتف',
      'parent_name': 'اسم ولي الأمر',
      'parent_phone': 'هاتف ولي الأمر',
      'enrollment_date': 'تاريخ التسجيل',
      'status': 'الحالة',
      'created_at': 'تاريخ الإنشاء',
      'updated_at': 'تاريخ التحديث',
    };
    
    return translations[columnName.toLowerCase()] ?? columnName;
  }
}
