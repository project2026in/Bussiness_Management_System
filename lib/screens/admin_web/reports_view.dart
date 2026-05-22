import 'package:flutter/material.dart';
import 'dart:convert';
import '../../utils/web_download.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  Map<String, String> _businessMap = {};
  Map<String, String> _ownerMap = {}; // mapping ownerId to ownerName
  Map<String, String> _userIdToName = {};
  Map<String, List<Map<String, String>>> _userBusinesses = {};
  bool _isLoading = true;
  String? _selectedBusinessId;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
  }

  Future<void> _fetchMetadata() async {
    try {
      // Fetch businesses
      final busQuery = await FirebaseFirestore.instance.collection('businesses').get();
      Map<String, String> bMap = {};
      Map<String, String> bOwnerMap = {};
      for (var doc in busQuery.docs) {
        final data = doc.data();
        bMap[doc.id] = data['name'] ?? 'Unknown Business';
        final ownerId = data['owner_id'] ?? data['ownerId'] ?? data['owner'];
        if (ownerId != null) {
          bOwnerMap[doc.id] = ownerId;
        }
      }

      // Fetch users (owners)
      final usersQuery = await FirebaseFirestore.instance.collection('users').get();
      Map<String, String> uMap = {};
      for (var doc in usersQuery.docs) {
        final data = doc.data();
        uMap[doc.id] = data['name'] ?? 'Unknown User';
      }

      // Create business -> owner name mapping
      Map<String, String> finalOwnerMap = {};
      Map<String, List<Map<String, String>>> userBuses = {};

      for (var bid in bMap.keys) {
        final oId = bOwnerMap[bid];
        if (oId != null && uMap.containsKey(oId)) {
          finalOwnerMap[bid] = uMap[oId]!;
          userBuses.putIfAbsent(oId, () => []).add({'id': bid, 'name': bMap[bid]!});
        } else {
          finalOwnerMap[bid] = 'Unknown Owner';
        }
      }

      if (mounted) {
        setState(() {
          _businessMap = bMap;
          _ownerMap = finalOwnerMap;
          _userIdToName = uMap;
          _userBusinesses = userBuses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading metadata: $e')),
        );
      }
    }
  }

  Future<void> _importJsonData() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to read file.')));
        return;
      }

      final jsonString = utf8.decode(fileBytes);
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid JSON format: Expected a List.')));
        return;
      }

      bool isDialogShowing = true;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        ).then((_) => isDialogShowing = false);
      }

      try {
        final batch = FirebaseFirestore.instance.batch();
        final collRef = FirebaseFirestore.instance.collection('daily_reports');
        int count = 0;

        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            if (!item.containsKey('business_id')) continue;
            DateTime? parsedDate;
            if (item['date'] is String) parsedDate = DateTime.tryParse(item['date']);
            if (parsedDate == null) continue;

            final sale = (item['sale'] as num?)?.toDouble() ?? 0.0;
            final purchase = (item['purchase'] as num?)?.toDouble() ?? 0.0;
            final expense = (item['expense'] as num?)?.toDouble() ?? 0.0;
            final salary = (item['salary'] as num?)?.toDouble() ?? 0.0;
            final otherExpense = (item['other_expense'] as num?)?.toDouble() ?? 0.0;

            final docRef = collRef.doc();
            batch.set(docRef, {
              'business_id': item['business_id'],
              'date': Timestamp.fromDate(parsedDate),
              'sale': sale,
              'purchase': purchase,
              'expense': expense,
              'salary': salary,
              'other_expense': otherExpense,
            });
            count++;
          }
        }

        if (count > 0) {
          await batch.commit();
        }

        if (mounted) {
          if (isDialogShowing) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully imported $count reports!')));
        }
      } catch (e) {
        if (mounted && isDialogShowing) Navigator.pop(context);
        rethrow;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing JSON: $e')));
      }
    }
  }

  Future<void> _exportJsonData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('daily_reports').get();
      final List<Map<String, dynamic>> jsonList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        data.forEach((key, value) {
          if (value is Timestamp) {
            data[key] = value.toDate().toIso8601String();
          }
        });
        jsonList.add(data);
      }
      final jsonString = jsonEncode(jsonList);
      downloadJsonFile(jsonString, 'daily_reports.json');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded daily_reports.json')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error downloading JSON: $e')));
      }
    }
  }

  Future<void> _generatePdf(int year, int month, List<Map<String, dynamic>> reports, double mSales, double mPurchases, double mPureExp, double mSalary, double mOther, double mExp, String businessName, String ownerName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Heading
            pw.Center(
              child: pw.Text('Monthly Business Report (${DateFormat('MMMM yyyy').format(DateTime(year, month))})', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            
            // Business Details
            pw.Text('Business Name: $businessName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            // Owner Details
            pw.Text('Owner Name: $ownerName'),
            pw.SizedBox(height: 30),

            // Table
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Sales', 'Purchases', 'Exp', 'Salary', 'Other', 'Total Exp', 'Profit'],
              data: [
                ...reports.map((row) {
                  final d = row['date'] as DateTime;
                  final dateStr = DateFormat('MMM dd, yyyy').format(d);
                  return [
                    dateStr,
                    row['sale'].toStringAsFixed(2),
                    row['purchase'].toStringAsFixed(2),
                    row['expense'].toStringAsFixed(2),
                    row['salary'].toStringAsFixed(2),
                    row['other'].toStringAsFixed(2),
                    row['totalExpense'].toStringAsFixed(2),
                    row['profit'].toStringAsFixed(2),
                  ];
                }),
                // Total Row
                [
                  'TOTAL',
                  mSales.toStringAsFixed(2),
                  mPurchases.toStringAsFixed(2),
                  mPureExp.toStringAsFixed(2),
                  mSalary.toStringAsFixed(2),
                  mOther.toStringAsFixed(2),
                  mExp.toStringAsFixed(2),
                  (mSales - mExp).toStringAsFixed(2),
                ]
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
              cellAlignment: pw.Alignment.centerRight,
              cellAlignments: {0: pw.Alignment.centerLeft},
            ),
          ];
        },
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Text('Generated by admin', style: pw.TextStyle(color: PdfColors.grey, fontStyle: pw.FontStyle.italic)),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${businessName}_Report_${year}_$month.pdf',
    );
  }

  Future<void> _downloadReportForAdmin(String businessId, int year, int month) async {
    bool isDialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    ).then((_) => isDialogShowing = false);

    try {
      final reportsQuery = await FirebaseFirestore.instance
          .collection('daily_reports')
          .where('business_id', isEqualTo: businessId)
          .get();
      
      double mSales = 0;
      double mExp = 0;
      double mPurchases = 0;
      double mPureExp = 0;
      double mSalary = 0;
      double mOther = 0;
      List<Map<String, dynamic>> reports = [];

      for (var doc in reportsQuery.docs) {
        final data = doc.data();
        final docDate = (data['date'] as Timestamp?)?.toDate();
        if (docDate != null && docDate.year == year && docDate.month == month) {
          final sale = (data['sale'] as num?)?.toDouble() ?? 0.0;
          final purchase = (data['purchase'] as num?)?.toDouble() ?? 0.0;
          final expense = (data['expense'] as num?)?.toDouble() ?? 0.0;
          final salary = (data['salary'] as num?)?.toDouble() ?? 0.0;
          final other = (data['other_expense'] as num?)?.toDouble() ?? 0.0;
          final totalExpense = purchase + expense + salary + other;

          mSales += sale;
          mExp += totalExpense;
          mPurchases += purchase;
          mPureExp += expense;
          mSalary += salary;
          mOther += other;

          reports.add({
            'date': docDate,
            'sale': sale,
            'purchase': purchase,
            'expense': expense,
            'salary': salary,
            'other': other,
            'totalExpense': totalExpense,
            'profit': sale - totalExpense,
          });
        }
      }

      reports.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      if (isDialogShowing && mounted) {
        Navigator.pop(context); // close loading
        isDialogShowing = false;
      }

      if (reports.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No reports found for the selected month.')));
        }
        return;
      }

      final businessName = _businessMap[businessId] ?? 'Unknown Business';
      final ownerName = _ownerMap[businessId] ?? 'Unknown Owner';

      await _generatePdf(year, month, reports, mSales, mPurchases, mPureExp, mSalary, mOther, mExp, businessName, ownerName);

    } catch (e) {
      if (mounted) {
        if (isDialogShowing) {
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    }
  }

  void _showDownloadDialog() {
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;
    String? selectedUserId;
    String? selectedBusinessId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final availableOwners = _userBusinesses.keys.toList();
            final ownerItems = availableOwners.map((uid) {
              return DropdownMenuItem<String>(
                value: uid,
                child: Text(_userIdToName[uid] ?? 'Unknown'),
              );
            }).toList();

            List<DropdownMenuItem<String>> businessItems = [];
            if (selectedUserId != null && _userBusinesses.containsKey(selectedUserId)) {
              businessItems = _userBusinesses[selectedUserId!]!.map((b) {
                return DropdownMenuItem<String>(
                  value: b['id'],
                  child: Text(b['name'] ?? 'Unknown'),
                );
              }).toList();
            }

            return AlertDialog(
              title: const Text('Download Monthly Report', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Owner Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Owner: ', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('Select Owner'),
                                value: selectedUserId,
                                items: ownerItems,
                                onChanged: (val) {
                                  setStateDialog(() {
                                    selectedUserId = val;
                                    selectedBusinessId = null; // Reset business on owner change
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Business Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Business: ', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text('Select Business'),
                                value: selectedBusinessId,
                                items: businessItems,
                                onChanged: selectedUserId == null ? null : (val) {
                                  setStateDialog(() => selectedBusinessId = val);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Year Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Year: ', style: TextStyle(fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedYear,
                              items: List.generate(5, (index) => DateTime.now().year - index)
                                  .map<DropdownMenuItem<int>>((year) => DropdownMenuItem<int>(value: year, child: Text(year.toString())))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setStateDialog(() => selectedYear = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Month Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Month: ', style: TextStyle(fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedMonth,
                              items: List.generate(12, (index) => index + 1).map<DropdownMenuItem<int>>((month) {
                                final date = DateTime(selectedYear, month);
                                return DropdownMenuItem<int>(
                                  value: month,
                                  child: Text(DateFormat('MMMM').format(date)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setStateDialog(() => selectedMonth = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: selectedBusinessId == null ? null : () {
                    Navigator.pop(context);
                    _downloadReportForAdmin(selectedBusinessId!, selectedYear, selectedMonth);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Download'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedBusinessId = null;
      _selectedDate = null;
    });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'System Reports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View all financial reports submitted across all businesses.',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          
          // Filters
          Row(
            children: [
              Container(
                width: 250,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
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
              const SizedBox(width: 16),
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
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(width: 16),
              if (_selectedDate != null || _selectedBusinessId != null)
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear, size: 18),
                  label: const Text('Clear Filters'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _exportJsonData,
                icon: const Icon(Icons.download_for_offline, size: 18),
                label: const Text('Export JSON'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _importJsonData,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Import JSON'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                  backgroundColor: Colors.blue.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _showDownloadDialog,
                icon: const Icon(Icons.download),
                label: const Text('Download Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Reports Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('daily_reports')
                    // Not ordering by date via query to prevent missing index errors
                    // Instead we will sort in memory.
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading reports.\nCheck your Firebase Security Rules.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    );
                  }

                  var docs = snapshot.data?.docs ?? [];
                  
                  // Sort descending by date
                  docs.sort((a, b) {
                    final dataA = a.data() as Map<String, dynamic>;
                    final dataB = b.data() as Map<String, dynamic>;
                    final dateA = (dataA['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                    final dateB = (dataB['date'] as Timestamp?)?.toDate() ?? DateTime(2000);
                    return dateB.compareTo(dateA);
                  });

                  // Filter in memory
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    bool matchesBusiness = true;
                    bool matchesDate = true;

                    if (_selectedBusinessId != null) {
                      matchesBusiness = data['business_id'] == _selectedBusinessId;
                    }

                    if (_selectedDate != null) {
                      final docDate = (data['date'] as Timestamp?)?.toDate();
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

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Text('No reports found matching criteria.'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                        columns: const [
                          DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Business', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Owner', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Income', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Net', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: filteredDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final date = (data['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                          final dateStr = DateFormat('MMM d, yyyy').format(date);
                          final businessId = data['business_id'] ?? '';
                          final businessName = _businessMap[businessId] ?? 'Unknown';
                          final ownerName = _ownerMap[businessId] ?? 'Unknown';

                          final income = (data['sale'] as num?)?.toDouble() ?? 0.0;
                          final purchase = (data['purchase'] as num?)?.toDouble() ?? 0.0;
                          final expense = (data['expense'] as num?)?.toDouble() ?? 0.0;
                          final salary = (data['salary'] as num?)?.toDouble() ?? 0.0;
                          final other = (data['other_expense'] as num?)?.toDouble() ?? 0.0;
                          final totalExpense = purchase + expense + salary + other;
                          final profit = income - totalExpense;

                          final statusColor = profit >= 0 ? Colors.green : Colors.red;

                          return DataRow(
                            cells: [
                              DataCell(Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w500))),
                              DataCell(Text(businessName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)))),
                              DataCell(Text(ownerName)),
                              DataCell(Text('\$${income.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green))),
                              DataCell(Text('\$${totalExpense.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red))),
                              DataCell(Text('\$${profit.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: statusColor))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    profit >= 0 ? 'PROFIT' : 'LOSS',
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
