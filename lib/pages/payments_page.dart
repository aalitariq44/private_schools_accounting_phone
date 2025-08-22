import 'package:flutter/material.dart';
import '../services/db_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _statusFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final payments = await DatabaseService.getPayments();

      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في تحميل بيانات الأقساط: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredPayments {
    var filtered = _payments;

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        final amount = payment['amount']?.toString().toLowerCase() ?? '';
        final studentId = payment['student_id']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return amount.contains(query) || studentId.contains(query);
      }).toList();
    }

    // فلترة حسب الحالة
    if (_statusFilter != 'الكل') {
      filtered = filtered.where((payment) {
        final status = payment['status']?.toString() ?? '';
        return status == _statusFilter;
      }).toList();
    }

    return filtered;
  }

  List<String> get _availableStatuses {
    final statuses = _payments
        .map((payment) => payment['status']?.toString() ?? 'غير محدد')
        .toSet()
        .toList();
    statuses.insert(0, 'الكل');
    return statuses;
  }

  double get _totalAmount {
    return _filteredPayments.fold(0.0, (sum, payment) {
      final amount =
          double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0;
      return sum + amount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقساط'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadPayments,
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
                  Text('جاري تحميل بيانات الأقساط...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPayments,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            )
          : _payments.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'لا توجد أقساط مسجلة',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // شريط البحث والفلاتر
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // شريط البحث
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'البحث في الأقساط',
                          hintText: 'أدخل المبلغ أو رقم الطالب...',
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

                      // فلتر الحالة
                      Row(
                        children: [
                          const Text('الحالة: '),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _statusFilter,
                              isExpanded: true,
                              items: _availableStatuses
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _statusFilter = value ?? 'الكل';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // الإحصائيات
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.payment, color: Colors.orange),
                                const SizedBox(height: 4),
                                Text(
                                  '${_payments.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                const Text('إجمالي الأقساط'),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.filter_list,
                                  color: Colors.blue,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_filteredPayments.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const Text('نتائج البحث'),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: Colors.green,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _totalAmount.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Text('إجمالي المبلغ'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // قائمة الأقساط
                Expanded(
                  child: _filteredPayments.isEmpty
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
                      : _buildPaymentsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildPaymentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPayments.length,
      itemBuilder: (context, index) {
        final payment = _filteredPayments[index];
        final amount =
            double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0;
        final status = payment['status']?.toString() ?? 'غير محدد';

        Color statusColor = Colors.grey;
        IconData statusIcon = Icons.help_outline;

        switch (status.toLowerCase()) {
          case 'paid':
          case 'مدفوع':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'pending':
          case 'معلق':
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            break;
          case 'overdue':
          case 'متأخر':
            statusColor = Colors.red;
            statusIcon = Icons.warning;
            break;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(statusIcon, color: Colors.white),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'المبلغ: ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('رقم الطالب: ${payment['student_id'] ?? 'غير محدد'}'),
                Text(
                  'التاريخ: ${payment['payment_date'] ?? payment['date'] ?? 'غير محدد'}',
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: payment.entries
                      .map(
                        (entry) => Padding(
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
                                child: Text(
                                  entry.value?.toString() ?? 'غير محدد',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
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
      'student_id': 'رقم الطالب',
      'amount': 'المبلغ',
      'payment_date': 'تاريخ الدفع',
      'due_date': 'تاريخ الاستحقاق',
      'date': 'التاريخ',
      'status': 'الحالة',
      'type': 'النوع',
      'description': 'الوصف',
      'method': 'طريقة الدفع',
      'reference': 'المرجع',
      'notes': 'ملاحظات',
      'created_at': 'تاريخ الإنشاء',
      'updated_at': 'تاريخ التحديث',
    };

    return translations[columnName.toLowerCase()] ?? columnName;
  }
}
