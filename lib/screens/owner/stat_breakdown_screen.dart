import 'package:flutter/material.dart';

class StatBreakdownScreen extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> breakdownList;
  final bool isExpense;

  const StatBreakdownScreen({
    super.key,
    required this.title,
    required this.breakdownList,
    this.isExpense = false,
  });

  @override
  Widget build(BuildContext context) {
    // Group totals by business name
    final Map<String, double> aggregated = {};
    for (var item in breakdownList) {
      final name = item['business_name'] ?? 'Unknown Business';
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
      aggregated[name] = (aggregated[name] ?? 0) + amount;
    }

    final sortedEntries = aggregated.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalSum = sortedEntries.fold(0.0, (sum, entry) => sum + entry.value);
    final themeColor = isExpense ? Colors.red : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            width: double.infinity,
            child: Column(
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${totalSum.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sortedEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No data available for $title.', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(isExpense ? Icons.trending_down : Icons.trending_up, color: themeColor),
                          ),
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          trailing: Text(
                            '\$${entry.value.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: themeColor,
                            ),
                          ),
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
