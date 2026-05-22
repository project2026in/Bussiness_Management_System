import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'stat_breakdown_screen.dart';
import 'add_staff.dart';

class BusinessDetailsScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const BusinessDetailsScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  bool _isLoading = true;
  int _employeeCount = 0;
  
  double _todaySales = 0;
  double _todayExpenses = 0;
  double _monthSales = 0;
  double _monthExpenses = 0;

  List<Map<String, dynamic>> _todaySalesBreakdown = [];
  List<Map<String, dynamic>> _todayExpBreakdown = [];
  List<Map<String, dynamic>> _monthSalesBreakdown = [];
  List<Map<String, dynamic>> _monthExpBreakdown = [];
  
  List<Map<String, dynamic>> _monthlyReportsList = [];
  double _monthPurchases = 0;
  double _monthPureExpenses = 0;
  double _monthSalary = 0;
  double _monthOther = 0;

  Map<int, double> _dailyProfits = {};
  Map<int, double> _dailyExpenses = {};
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _fetchBusinessData();
  }

  Future<void> _fetchBusinessData() async {
    try {
      final String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (ownerId.isEmpty) return;

      final bDoc = await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).get();
      if (bDoc.exists) {
        _isActive = (bDoc.data() as Map<String, dynamic>)['is_active'] ?? true;
      }

      // 1. Fetch employees for this business
      final empQuery = await FirebaseFirestore.instance
          .collection('employees')
          .where('business_id', isEqualTo: widget.businessId)
          .get();
      
      int empCount = empQuery.docs.length;

      double todaySales = 0;
      double todayExp = 0;
      double monthSales = 0;
      double monthExp = 0;
      
      double monthPurchases = 0;
      double monthPureExpenses = 0;
      double monthSalary = 0;
      double monthOther = 0;
      List<Map<String, dynamic>> monthlyReports = [];

      List<Map<String, dynamic>> tsBreakdown = [];
      List<Map<String, dynamic>> teBreakdown = [];
      List<Map<String, dynamic>> msBreakdown = [];
      List<Map<String, dynamic>> meBreakdown = [];

      Map<int, double> dp = {};
      Map<int, double> de = {};

      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      final reportsQuery = await FirebaseFirestore.instance
          .collection('daily_reports')
          .where('business_id', isEqualTo: widget.businessId)
          .get();
      
      for (var doc in reportsQuery.docs) {
        final data = doc.data();
        final sale = (data['sale'] as num?)?.toDouble() ?? 0.0;
        final purchase = (data['purchase'] as num?)?.toDouble() ?? 0.0;
        final expense = (data['expense'] as num?)?.toDouble() ?? 0.0;
        final salary = (data['salary'] as num?)?.toDouble() ?? 0.0;
        final other = (data['other_expense'] as num?)?.toDouble() ?? 0.0;
        final totalExpense = purchase + expense + salary + other;
        
        final docDate = (data['date'] as Timestamp?)?.toDate();
        if (docDate != null) {
          final dateStr = DateFormat('MMM d, yyyy').format(docDate);

          // Check if Yesterday
          if (docDate.year == yesterday.year && docDate.month == yesterday.month && docDate.day == yesterday.day) {
            todaySales += sale;
            todayExp += totalExpense;
            if (sale > 0) tsBreakdown.add({'label': dateStr, 'amount': sale});
            if (totalExpense > 0) teBreakdown.add({'label': dateStr, 'amount': totalExpense});
          }
          // Check if This Month
          if (docDate.year == now.year && docDate.month == now.month) {
            monthSales += sale;
            monthExp += totalExpense;
            monthPurchases += purchase;
            monthPureExpenses += expense;
            monthSalary += salary;
            monthOther += other;
            
            monthlyReports.add({
              'date': docDate,
              'sale': sale,
              'purchase': purchase,
              'expense': expense,
              'salary': salary,
              'other': other,
              'totalExpense': totalExpense,
              'profit': sale - totalExpense,
            });

            dp[docDate.day] = (dp[docDate.day] ?? 0) + (sale - totalExpense);
            de[docDate.day] = (de[docDate.day] ?? 0) + totalExpense;
            if (sale > 0) msBreakdown.add({'label': dateStr, 'amount': sale});
            if (totalExpense > 0) meBreakdown.add({'label': dateStr, 'amount': totalExpense});
          }
        }
      }

      monthlyReports.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

      if (mounted) {
        setState(() {
          _employeeCount = empCount;
          _todaySales = todaySales;
          _todayExpenses = todayExp;
          _monthSales = monthSales;
          _monthExpenses = monthExp;
          _monthPurchases = monthPurchases;
          _monthPureExpenses = monthPureExpenses;
          _monthSalary = monthSalary;
          _monthOther = monthOther;
          _monthlyReportsList = monthlyReports;
          _todaySalesBreakdown = tsBreakdown;
          _todayExpBreakdown = teBreakdown;
          _monthSalesBreakdown = msBreakdown;
          _monthExpBreakdown = meBreakdown;
          _dailyProfits = dp;
          _dailyExpenses = de;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading business data: $e')),
        );
      }
    }
  }

  void _pushBreakdown(String title, List<Map<String, dynamic>> breakdown, bool isExpense) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatBreakdownScreen(
          title: title,
          breakdownList: breakdown,
          isExpense: isExpense,
        ),
      ),
    );
  }

  Future<void> _generatePdf(int year, int month, List<Map<String, dynamic>> reports, double mSales, double mPurchases, double mPureExp, double mSalary, double mOther, double mExp) async {
    final pdf = pw.Document();
    
    // Get user details
    final user = FirebaseAuth.instance.currentUser;
    String ownerName = user?.displayName ?? 'Owner';
    String email = user?.email ?? '';
    String phone = '';
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user?.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        ownerName = data['name'] ?? ownerName;
        phone = data['phone'] ?? phone;
      }
    } catch (_) {}

    // Get business details
    String city = '';
    String country = '';
    try {
      final bDoc = await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).get();
      if (bDoc.exists) {
        final data = bDoc.data()!;
        city = data['city'] ?? '';
        country = data['country'] ?? '';
      }
    } catch (_) {}

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
            pw.Text('Business Name: ${widget.businessName}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (city.isNotEmpty || country.isNotEmpty) pw.Text('Location: $city, $country'),
            pw.SizedBox(height: 10),

            // Owner Details
            pw.Text('Owner Name: $ownerName'),
            if (email.isNotEmpty) pw.Text('Email: $email'),
            if (phone.isNotEmpty) pw.Text('Phone: $phone'),
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
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${widget.businessName}_Report_${year}_$month.pdf',
    );
  }

  Future<void> _downloadReportForMonth(int year, int month) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final reportsQuery = await FirebaseFirestore.instance
          .collection('daily_reports')
          .where('business_id', isEqualTo: widget.businessId)
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

      if (mounted) Navigator.pop(context); // close loading

      if (reports.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No reports found for the selected month.')));
        }
        return;
      }

      await _generatePdf(year, month, reports, mSales, mPurchases, mPureExp, mSalary, mOther, mExp);

    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    }
  }

  void _showMonthSelectionDialog() {
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Month', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Year: ', style: TextStyle(fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedYear,
                            items: List.generate(5, (index) => DateTime.now().year - index)
                                .map((year) => DropdownMenuItem(value: year, child: Text(year.toString())))
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Month: ', style: TextStyle(fontSize: 16)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: selectedMonth,
                            items: List.generate(12, (index) => index + 1).map((month) {
                              final date = DateTime(selectedYear, month);
                              return DropdownMenuItem(
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadReportForMonth(selectedYear, selectedMonth);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.businessName, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'toggle_status') {
                final actionText = _isActive ? 'Deactivate' : 'Activate';
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('$actionText Business'),
                    content: Text('Are you sure you want to ${actionText.toLowerCase()} this business?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _isActive ? Colors.red : Colors.green, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(context, true), 
                        child: Text(actionText)
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  try {
                    await FirebaseFirestore.instance.collection('businesses').doc(widget.businessId).update({
                      'is_active': !_isActive,
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Business ${actionText.toLowerCase()}d successfully.')));
                      setState(() {
                        _isActive = !_isActive;
                      });
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating business status: $e')));
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(_isActive ? Icons.block : Icons.check_circle, color: _isActive ? Colors.red : Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(_isActive ? 'Deactivate' : 'Activate', style: TextStyle(color: _isActive ? Colors.red : Colors.green)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBusinessData,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.only(top: 20, left: 24, right: 24, bottom: 30),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BusinessEmployeesScreen(
                                          businessId: widget.businessId,
                                          businessName: widget.businessName,
                                        ),
                                      ),
                                    );
                                  },
                                  child: _buildHeaderStat('Employees', '$_employeeCount', Icons.people),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          "Yesterday's Financials",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pushBreakdown("Yesterday's Sales", _todaySalesBreakdown, false),
                                child: _buildGradientCard(
                                  title: "Sales",
                                  value: '\$${_todaySales.toStringAsFixed(0)}',
                                  icon: Icons.trending_up,
                                  colors: [const Color(0xFF10B981), const Color(0xFF059669)],
                                  isSmall: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pushBreakdown("Yesterday's Expenses", _todayExpBreakdown, true),
                                child: _buildGradientCard(
                                  title: "Expenses",
                                  value: '\$${_todayExpenses.toStringAsFixed(0)}',
                                  icon: Icons.trending_down,
                                  colors: [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                                  isSmall: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildProfitChart(),
                        const SizedBox(height: 32),
                        const Text(
                          "This Month's Financials",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _pushBreakdown("This Month's Sales", _monthSalesBreakdown, false),
                          child: _buildGradientCard(
                            title: "Monthly Sales",
                            value: '\$${_monthSales.toStringAsFixed(2)}',
                            icon: Icons.assessment,
                            colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => _pushBreakdown("This Month's Expenses", _monthExpBreakdown, true),
                          child: _buildGradientCard(
                            title: "Monthly Expenses",
                            value: '\$${_monthExpenses.toStringAsFixed(2)}',
                            icon: Icons.receipt_long,
                            colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                          ),
                        ),
                        const SizedBox(height: 32),
                        _buildExpenseChart(),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showMonthSelectionDialog,
                            icon: const Icon(Icons.download),
                            label: const Text('Download Monthly Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildGradientCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: isSmall ? 24 : 32),
          ),
          SizedBox(width: isSmall ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isSmall ? 24 : 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitChart() {
    if (_dailyProfits.isEmpty) return const SizedBox.shrink();

    // Prepare chart data
    List<FlSpot> spots = [];
    final now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    double maxProfit = 0;
    double minProfit = 0;
    double totalMonthlyProfit = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      double profit = _dailyProfits[i] ?? 0.0;
      totalMonthlyProfit += profit;
      spots.add(FlSpot(i.toDouble(), profit));
      if (profit > maxProfit) maxProfit = profit;
      if (profit < minProfit) minProfit = profit;
    }

    maxProfit = maxProfit == 0 ? 100 : maxProfit * 1.2;
    minProfit = minProfit == 0 ? 0 : minProfit * 1.2;

    bool isProfitable = totalMonthlyProfit >= 0;
    Color graphColor = isProfitable ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    String statusText = isProfitable ? "Overall Profit" : "Overall Loss";
    IconData statusIcon = isProfitable ? Icons.trending_up : Icons.trending_down;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                "Profit Trajectory",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: graphColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: graphColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(color: graphColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          padding: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: minProfit,
                maxY: maxProfit,
                lineTouchData: const LineTouchData(enabled: false), 
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: graphColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          graphColor.withValues(alpha: 0.4),
                          graphColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseChart() {
    if (_dailyExpenses.isEmpty) return const SizedBox.shrink();

    List<FlSpot> spots = [];
    final now = DateTime.now();
    int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    double maxExp = 0;
    double minExp = 0;

    for (int i = 1; i <= daysInMonth; i++) {
      double exp = _dailyExpenses[i] ?? 0.0;
      spots.add(FlSpot(i.toDouble(), exp));
      if (exp > maxExp) maxExp = exp;
      if (exp < minExp) minExp = exp;
    }

    maxExp = maxExp == 0 ? 100 : maxExp * 1.2;
    minExp = minExp == 0 ? 0 : minExp * 1.2;

    Color graphColor = const Color(0xFFEF4444);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                "Expense Trajectory",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: graphColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: graphColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "Burn Rate",
                    style: TextStyle(color: graphColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 160,
          padding: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 1,
                maxX: daysInMonth.toDouble(),
                minY: minExp,
                maxY: maxExp,
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: graphColor,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          graphColor.withValues(alpha: 0.4),
                          graphColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class BusinessEmployeesScreen extends StatelessWidget {
  final String businessId;
  final String businessName;

  const BusinessEmployeesScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employees - $businessName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStaffScreen()),
          );
        },
        tooltip: 'Add Staff Member',
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('employees')
              .where('business_id', isEqualTo: businessId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading employees.', style: TextStyle(color: Colors.red)),
              );
            }

            var docs = snapshot.data?.docs.toList() ?? [];

            // Sort by created_at descending
            docs.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTimeStr = aData['created_at']?.toString() ?? '';
              final bTimeStr = bData['created_at']?.toString() ?? '';
              return bTimeStr.compareTo(aTimeStr);
            });

            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No employees assigned to this business.\nTap the + button to add one!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final name = data['name'] ?? 'Unknown';
                final email = data['email'] ?? 'No email';
                final role = data['role'] ?? 'Employee';
                final isActive = data['is_active'] ?? true;

                final statusColor = isActive ? Colors.green : Colors.red;
                final roleColor = role == 'Manager' ? Colors.purple : Colors.blue;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.1),
                      radius: 28,
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(color: roleColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.email, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(email, style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
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
    );
  }
}
