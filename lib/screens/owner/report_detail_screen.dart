import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportDetailScreen extends StatelessWidget {
  final Map<String, dynamic> reportData;

  const ReportDetailScreen({super.key, required this.reportData});

  @override
  Widget build(BuildContext context) {
    final date = (reportData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final businessName = reportData['business_name'] ?? 'Unknown Business';

    final income = (reportData['sale'] as num?)?.toDouble() ?? 0.0;
    final purchase = (reportData['purchase'] as num?)?.toDouble() ?? 0.0;
    final expense = (reportData['expense'] as num?)?.toDouble() ?? 0.0;
    final salary = (reportData['salary'] as num?)?.toDouble() ?? 0.0;
    final other = (reportData['other_expense'] as num?)?.toDouble() ?? 0.0;
    final bank = (reportData['bank'] as num?)?.toDouble() ?? 0.0;
    final cash = (reportData['cash'] as num?)?.toDouble() ?? 0.0;

    final totalExpense = purchase + expense + salary + other;
    final profit = income - totalExpense;
    final profitPercentage = income == 0 ? 0.0 : (profit / income) * 100;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Date Header
          Container(
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
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(date),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 4),
                Text(
                  businessName,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // Details List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0, left: 4),
                  child: Text('Distribution Breakdown', style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
                _buildReadOnlyItem('Income / Sales', income, Icons.trending_up, Colors.green),
                _buildReadOnlyItem('Purchases', purchase, Icons.shopping_cart, Colors.orange),
                _buildReadOnlyItem('General Expense', expense, Icons.receipt_long, Colors.red),
                _buildReadOnlyItem('Salary Paid', salary, Icons.people, Colors.purple),
                _buildReadOnlyItem('Other Expenses', other, Icons.money_off, Colors.redAccent),
                _buildReadOnlyItem('Bank Balance', bank, Icons.account_balance, Colors.blue),
                _buildReadOnlyItem('Cash in Register', cash, Icons.payments, Colors.teal),
                
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
                            Text('\$${income.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Expense', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text('\$${totalExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                  '\$${profit.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: profit >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  '${profitPercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: profitPercentage >= 0 ? Colors.green : Colors.red,
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
                            value: income == 0 ? 0 : (profit > 0 ? profit / income : 0),
                            backgroundColor: Colors.grey.shade200,
                            color: profit >= 0 ? Colors.green : Colors.red,
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildReadOnlyItem(String title, double amount, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '\$${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }
}
