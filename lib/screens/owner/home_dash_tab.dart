import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'owner_dash.dart';
import 'stat_breakdown_screen.dart';

class HomeDashboardTab extends StatefulWidget {
  final Function(int)? onNavigate;
  const HomeDashboardTab({super.key, this.onNavigate});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  bool _isLoading = true;
  int _businessCount = 0;
  int _employeeCount = 0;
  
  double _todaySales = 0;
  double _todayExpenses = 0;
  double _monthSales = 0;
  double _monthExpenses = 0;

  List<Map<String, dynamic>> _todaySalesBreakdown = [];
  List<Map<String, dynamic>> _todayExpBreakdown = [];
  List<Map<String, dynamic>> _monthSalesBreakdown = [];
  List<Map<String, dynamic>> _monthExpBreakdown = [];

  Map<int, double> _dailyProfits = {};
  Map<int, double> _dailyExpenses = {};

  @override
  void initState() {
    super.initState();
    _fetchAggregateData();
  }

  Future<void> _fetchAggregateData() async {
    try {
      final String ownerId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (ownerId.isEmpty) return;

      // 1. Fetch businesses and filter locally to handle legacy schema keys
      final busQuery = await FirebaseFirestore.instance.collection('businesses').get();
      final userBusinesses = busQuery.docs.where((d) {
        final data = d.data();
        final oId = data['owner_id'] ?? data['ownerId'] ?? data['owner'];
        return oId == ownerId;
      }).toList();
      
      int busCount = userBusinesses.length;
      List<String> businessIds = userBusinesses.map((d) => d.id).toList();
      Map<String, String> bMap = {};
      for (var doc in userBusinesses) {
        bMap[doc.id] = doc.data()['name'] ?? 'Unknown Business';
      }

      // 2. Fetch employees and filter locally
      final empQuery = await FirebaseFirestore.instance.collection('employees').get();
      final userEmployees = empQuery.docs.where((d) {
        final data = d.data();
        final oId = data['owner_id'] ?? data['ownerId'] ?? data['owner'];
        return oId == ownerId;
      }).toList();
      
      int empCount = userEmployees.length;

      // 3. Fetch reports for total sales and expenses
      double todaySales = 0;
      double todayExp = 0;
      double monthSales = 0;
      double monthExp = 0;

      List<Map<String, dynamic>> tsBreakdown = [];
      List<Map<String, dynamic>> teBreakdown = [];
      List<Map<String, dynamic>> msBreakdown = [];
      List<Map<String, dynamic>> meBreakdown = [];

      Map<int, double> dp = {};
      Map<int, double> de = {};

      final now = DateTime.now();

      for (var bid in businessIds) {
        final reportsQuery = await FirebaseFirestore.instance
            .collection('daily_reports')
            .where('business_id', isEqualTo: bid)
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
            // Check if Today
            if (docDate.year == now.year && docDate.month == now.month && docDate.day == now.day) {
              todaySales += sale;
              todayExp += totalExpense;
              if (sale > 0) tsBreakdown.add({'business_name': bMap[bid], 'amount': sale});
              if (totalExpense > 0) teBreakdown.add({'business_name': bMap[bid], 'amount': totalExpense});
            }
            // Check if This Month
            if (docDate.year == now.year && docDate.month == now.month) {
              monthSales += sale;
              monthExp += totalExpense;
              dp[docDate.day] = (dp[docDate.day] ?? 0) + (sale - totalExpense);
              de[docDate.day] = (de[docDate.day] ?? 0) + totalExpense;
              if (sale > 0) msBreakdown.add({'business_name': bMap[bid], 'amount': sale});
              if (totalExpense > 0) meBreakdown.add({'business_name': bMap[bid], 'amount': totalExpense});
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _businessCount = busCount;
          _employeeCount = empCount;
          _todaySales = todaySales;
          _todayExpenses = todayExp;
          _monthSales = monthSales;
          _monthExpenses = monthExp;
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
          SnackBar(content: Text('Error loading dashboard data: $e')),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _fetchAggregateData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 30),
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
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyShopsScreen()));
                          },
                          child: _buildHeaderStat('Businesses', '$_businessCount', Icons.storefront),
                        ),
                        Container(width: 1, height: 40, color: Colors.white30),
                        InkWell(
                          onTap: () {
                            if (widget.onNavigate != null) {
                              widget.onNavigate!(1); // Navigate to Staff Tab
                            }
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
                  "Today's Financials",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pushBreakdown("Today's Sales", _todaySalesBreakdown, false),
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
                        onTap: () => _pushBreakdown("Today's Expenses", _todayExpBreakdown, true),
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
              ]),
            ),
          ),
        ],
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

    // Add some padding to Y axis
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
                "Total Business Trajectory",
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
                lineTouchData: const LineTouchData(enabled: false), // Disable touch to make it a pure visual sparkline
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

    Color graphColor = const Color(0xFFEF4444); // Red color for expenses

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
