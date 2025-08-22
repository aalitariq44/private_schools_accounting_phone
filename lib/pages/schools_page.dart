import 'package:flutter/material.dart';
import '../services/db_service.dart';

class SchoolsPage extends StatefulWidget {
  const SchoolsPage({super.key});

  @override
  State<SchoolsPage> createState() => _SchoolsPageState();
}

class _SchoolsPageState extends State<SchoolsPage> {
  List<Map<String, dynamic>> _schools = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final schools = await DatabaseService.getSchools();
      
      setState(() {
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل بيانات المدارس: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المدارس'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadSchools,
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
                  Text('جاري تحميل بيانات المدارس...'),
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
                        onPressed: _loadSchools,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _schools.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد مدارس مسجلة',
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
                        // عرض إحصائيات سريعة
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Icon(Icons.school, color: Colors.blue),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_schools.length}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const Text('إجمالي المدارس'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // قائمة المدارس
                        Expanded(
                          child: _schools.length <= 10
                              ? _buildDataTable()
                              : _buildListView(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildDataTable() {
    final columns = _schools.isNotEmpty ? _schools.first.keys.toList() : [];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columns: columns
              .map((column) => DataColumn(
                    label: Text(
                      _translateColumnName(column),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ))
              .toList(),
          rows: _schools
              .map((school) => DataRow(
                    cells: columns
                        .map((column) => DataCell(
                              Text(school[column]?.toString() ?? ''),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schools.length,
      itemBuilder: (context, index) {
        final school = _schools[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: const Icon(Icons.school, color: Colors.blue),
            title: Text(
              school['name']?.toString() ?? school['school_name']?.toString() ?? 'مدرسة غير محددة',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('الرقم التعريفي: ${school['id'] ?? 'غير محدد'}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: school.entries
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
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _translateColumnName(String columnName) {
    final translations = {
      'id': 'المعرف',
      'name': 'الاسم',
      'school_name': 'اسم المدرسة',
      'address': 'العنوان',
      'phone': 'الهاتف',
      'email': 'البريد الإلكتروني',
      'director': 'المدير',
      'established_date': 'تاريخ التأسيس',
      'type': 'النوع',
      'level': 'المرحلة',
      'created_at': 'تاريخ الإنشاء',
      'updated_at': 'تاريخ التحديث',
    };
    
    return translations[columnName.toLowerCase()] ?? columnName;
  }
}
