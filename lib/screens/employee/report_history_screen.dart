import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportHistoryScreen extends StatefulWidget {
  final String cashierId;

  const ReportHistoryScreen({super.key, required this.cashierId});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  DateTime? _filterDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

  void _clearFilter() {
    setState(() {
      _filterDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('All Daily Reports'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _filterDate == null 
                        ? 'Showing all time' 
                        : 'Filtered: ${DateFormat('MMM d, yyyy').format(_filterDate!)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
                if (_filterDate != null)
                  TextButton.icon(
                    onPressed: _clearFilter,
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _selectDate(context),
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('Pick Date'),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF0D47A1)),
                  ),
              ],
            ),
          ),
          
          // List View
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('daily_reports')
                  .where('cashier_id', isEqualTo: widget.cashierId)
                  .snapshots(),
              builder: (context, reportSnap) {
                if (reportSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (reportSnap.hasError) {
                  return const Center(child: Text('Error loading history.', style: TextStyle(color: Colors.red)));
                }
                if (!reportSnap.hasData || reportSnap.data!.docs.isEmpty) {
                  return const Center(child: Text('No daily reports found.'));
                }

                // Convert and filter docs locally
                var docs = reportSnap.data!.docs.toList();
                
                if (_filterDate != null) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp?)?.toDate();
                    if (date == null) return false;
                    return date.year == _filterDate!.year && 
                           date.month == _filterDate!.month && 
                           date.day == _filterDate!.day;
                  }).toList();
                }

                // Sort documents descending
                docs.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  final dateA = (dataA['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  final dateB = (dataB['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                  return dateB.compareTo(dateA); // Descending order
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text('No reports found for this date.', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final report = docs[index].data() as Map<String, dynamic>;
                    final date = (report['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                    final dateStr = DateFormat('EEEE, MMM d, yyyy').format(date);
                    
                    final income = (report['sale'] as num?)?.toDouble() ?? 0.0;
                    final purchase = (report['purchase'] as num?)?.toDouble() ?? 0.0;
                    final expense = (report['expense'] as num?)?.toDouble() ?? 0.0;
                    final salary = (report['salary'] as num?)?.toDouble() ?? 0.0;
                    final other = (report['other_expense'] as num?)?.toDouble() ?? 0.0;
                    final totalExpense = purchase + expense + salary + other;
                    final profit = income - totalExpense;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: profit >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          child: Icon(
                            profit >= 0 ? Icons.trending_up : Icons.trending_down,
                            color: profit >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Income: \$${income.toStringAsFixed(0)}\nTotal Expense: \$${totalExpense.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${profit.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: profit >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                            Text(
                              'Profit',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
