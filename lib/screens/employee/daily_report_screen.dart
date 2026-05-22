import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyReportScreen extends StatefulWidget {
  final String businessId;
  final String cashierId;

  const DailyReportScreen({
    super.key,
    required this.businessId,
    required this.cashierId,
  });

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  final Map<String, TextEditingController> _controllers = {
    'sale': TextEditingController(),
    'purchase': TextEditingController(),
    'expense': TextEditingController(),
    'salary': TextEditingController(),
    'other_expense': TextEditingController(),
    'bank': TextEditingController(),
    'cash': TextEditingController(),
  };

  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  double get _income {
    return double.tryParse(_controllers['sale']!.text) ?? 0.0;
  }

  double get _totalExpense {
    final purchase = double.tryParse(_controllers['purchase']!.text) ?? 0.0;
    final expense = double.tryParse(_controllers['expense']!.text) ?? 0.0;
    final salary = double.tryParse(_controllers['salary']!.text) ?? 0.0;
    final other = double.tryParse(_controllers['other_expense']!.text) ?? 0.0;
    return purchase + expense + salary + other;
  }

  double get _profit {
    return _income - _totalExpense;
  }

  double get _profitPercentage {
    if (_income == 0) return 0.0;
    return (_profit / _income) * 100;
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to all controllers to trigger rebuild for bottom bar calculations
    for (var controller in _controllers.values) {
      controller.addListener(() {
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (widget.businessId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No business assigned to your profile!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Check if a report for this exact date already exists
      final startOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
      final endOfDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);

      final existingReports = await FirebaseFirestore.instance
          .collection('daily_reports')
          .where('cashier_id', isEqualTo: widget.cashierId)
          .get();

      bool alreadySubmitted = false;
      for (var doc in existingReports.docs) {
        final docDate = (doc.data()['date'] as Timestamp?)?.toDate();
        if (docDate != null && 
            docDate.year == _selectedDate.year && 
            docDate.month == _selectedDate.month && 
            docDate.day == _selectedDate.day) {
          alreadySubmitted = true;
          break;
        }
      }

      if (alreadySubmitted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A report for this date has already been submitted!'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          setState(() => _isSubmitting = false);
        }
        return;
      }

      final reportData = {
        'business_id': widget.businessId,
        'cashier_id': widget.cashierId,
        'date': Timestamp.fromDate(_selectedDate),
        'sale': double.tryParse(_controllers['sale']!.text) ?? 0.0,
        'purchase': double.tryParse(_controllers['purchase']!.text) ?? 0.0,
        'expense': double.tryParse(_controllers['expense']!.text) ?? 0.0,
        'salary': double.tryParse(_controllers['salary']!.text) ?? 0.0,
        'other_expense': double.tryParse(_controllers['other_expense']!.text) ?? 0.0,
        'bank': double.tryParse(_controllers['bank']!.text) ?? 0.0,
        'cash': double.tryParse(_controllers['cash']!.text) ?? 0.0,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('daily_reports').add(reportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily Report submitted successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Submit Daily Report'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date Header
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black12)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Reporting Date',
                        style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.edit_calendar, size: 16, color: Colors.grey.shade600),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)),
                  ),
                ],
              ),
            ),
          ),

          // Form List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0, left: 4),
                  child: Text('Tap a category to enter amount', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                _buildExpandableInput('Income / Sales', 'sale', Icons.trending_up, Colors.green),
                _buildExpandableInput('Purchases', 'purchase', Icons.shopping_cart, Colors.orange),
                _buildExpandableInput('General Expense', 'expense', Icons.receipt_long, Colors.red),
                _buildExpandableInput('Salary Paid', 'salary', Icons.people, Colors.purple),
                _buildExpandableInput('Other Expenses', 'other_expense', Icons.money_off, Colors.redAccent),
                _buildExpandableInput('Bank Balance', 'bank', Icons.account_balance, Colors.blue),
                _buildExpandableInput('Cash in Register', 'cash', Icons.payments, Colors.teal),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Income', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('\$${_income.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Expense', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('\$${_totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Profit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '\$${_profit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: _profit >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  '${_profitPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _profitPercentage >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('Profit Performance', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _income == 0 ? 0 : (_profit > 0 ? _profit / _income : 0),
                            backgroundColor: Colors.grey.shade200,
                            color: _profit >= 0 ? Colors.green : Colors.red,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Daily Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableInput(String title, String key, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          _controllers[key]!.text.isEmpty ? '0.00' : _controllers[key]!.text,
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _controllers[key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Enter Amount',
              prefixText: '\$ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }
}
