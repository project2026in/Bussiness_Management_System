import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  bool _isLoading = true;
  
  Map<String, String> _businessMap = {}; // id -> name
  List<Map<String, dynamic>> _allReports = [];
  
  String? _selectedBusinessId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (ownerId.isEmpty) return;

      // 1. Fetch businesses
      final busQuery = await FirebaseFirestore.instance.collection('businesses').get();
      final userBusinesses = busQuery.docs.where((d) {
        final data = d.data();
        final oId = data['owner_id'] ?? data['ownerId'] ?? data['owner'];
        return oId == ownerId;
      }).toList();

      Map<String, String> bMap = {};
      for (var doc in userBusinesses) {
        bMap[doc.id] = doc.data()['name'] ?? 'Unknown Business';
      }

      // 2. Fetch reports for each business
      List<Map<String, dynamic>> reports = [];
      for (var bid in bMap.keys) {
        final rQuery = await FirebaseFirestore.instance
            .collection('daily_reports')
            .where('business_id', isEqualTo: bid)
            .get();
            
        for (var doc in rQuery.docs) {
          final data = doc.data();
          data['doc_id'] = doc.id;
          data['business_name'] = bMap[bid]!;
          reports.add(data);
        }
      }

      // Sort reports by date descending
      reports.sort((a, b) {
        final dateA = (a['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final dateB = (b['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _businessMap = bMap;
          _allReports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedBusinessId = null;
      _selectedDate = null;
    });
  }

  List<Map<String, dynamic>> get _filteredReports {
    return _allReports.where((report) {
      bool matchesBusiness = true;
      bool matchesDate = true;

      if (_selectedBusinessId != null) {
        matchesBusiness = report['business_id'] == _selectedBusinessId;
      }

      if (_selectedDate != null) {
        final docDate = (report['date'] as Timestamp?)?.toDate();
        if (docDate == null) {
          matchesDate = false;
        } else {
          matchesDate = docDate.year == _selectedDate!.year &&
                        docDate.month == _selectedDate!.month &&
                        docDate.day == _selectedDate!.day;
        }
      }

      return matchesBusiness && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredReports;

    return Column(
      children: [
        // Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Business Dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedBusinessId,
                    hint: const Text('All Businesses'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Businesses', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ..._businessMap.entries.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedBusinessId = val),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Date and Clear
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      _selectedDate == null 
                        ? 'Filter by Date' 
                        : DateFormat('MMM d, yyyy').format(_selectedDate!),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _selectedDate == null ? Colors.grey.shade700 : const Color(0xFF0D47A1),
                    ),
                  ),
                  if (_selectedDate != null || _selectedBusinessId != null)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('View All'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                ],
              ),
            ],
          ),
        ),
        
        // List View
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchReports,
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('No reports found.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final report = filtered[index];
                      final date = (report['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                      final dateStr = DateFormat('EEEE, MMM d, yyyy').format(date);
                      final businessName = report['business_name'] ?? 'Unknown Business';

                      final income = (report['sale'] as num?)?.toDouble() ?? 0.0;
                      final purchase = (report['purchase'] as num?)?.toDouble() ?? 0.0;
                      final expense = (report['expense'] as num?)?.toDouble() ?? 0.0;
                      final salary = (report['salary'] as num?)?.toDouble() ?? 0.0;
                      final other = (report['other_expense'] as num?)?.toDouble() ?? 0.0;
                      final totalExpense = purchase + expense + salary + other;
                      final profit = income - totalExpense;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateStr,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      profit >= 0 ? 'PROFIT' : 'LOSS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.storefront, size: 16, color: Color(0xFF0D47A1)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      businessName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0D47A1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Income', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      Text('\$${income.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Expenses', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      Text('\$${totalExpense.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Net', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      Text(
                                        '\$${profit.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: profit >= 0 ? Colors.green : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
