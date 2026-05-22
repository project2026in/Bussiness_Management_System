import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'report_detail_screen.dart';

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
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
          child: Container(
            padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 48),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -20,
                  top: -40,
                  child: Icon(Icons.analytics, size: 160, color: Colors.white.withValues(alpha: 0.1)),
                ),
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      'Financial Reports',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchReports,
            child: CustomScrollView(
              slivers: [

          // Filters
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedBusinessId,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF0D47A1)),
                        hint: const Text('All Businesses', style: TextStyle(fontWeight: FontWeight.w600)),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Businesses', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                          ),
                          ..._businessMap.entries.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w500)),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedBusinessId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedDate == null ? Colors.white : const Color(0xFF0D47A1).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _selectedDate == null ? Colors.transparent : const Color(0xFF0D47A1)),
                              boxShadow: _selectedDate == null ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ] : [],
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: _selectedDate == null ? Colors.grey.shade600 : const Color(0xFF0D47A1)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null 
                                    ? 'Filter by Date' 
                                    : DateFormat('MMM d, yyyy').format(_selectedDate!),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _selectedDate == null ? Colors.grey.shade600 : const Color(0xFF0D47A1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (_selectedDate != null || _selectedBusinessId != null) ...[
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear, color: Colors.redAccent),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // List
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No reports found.', style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ReportDetailScreen(reportData: report)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey.shade800),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: profit >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: profit >= 0 ? Colors.green.shade200 : Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(profit >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            profit >= 0 ? 'PROFIT' : 'LOSS',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              color: profit >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFF0D47A1).withValues(alpha: 0.1), shape: BoxShape.circle),
                                      child: const Icon(Icons.storefront, size: 18, color: Color(0xFF0D47A1)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        businessName,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStatColumn('Income', income, Colors.green),
                                    _buildStatColumn('Expenses', totalExpense, Colors.red),
                                    _buildStatColumn('Net', profit, profit >= 0 ? Colors.green : Colors.red, isNet: true),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, double amount, Color color, {bool isNet = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(
          '\$${amount.toStringAsFixed(isNet ? 2 : 0)}',
          style: TextStyle(
            fontWeight: isNet ? FontWeight.w900 : FontWeight.bold,
            fontSize: isNet ? 18 : 16,
            color: isNet ? color : Colors.black87,
          ),
        ),
      ],
    );
  }
}
