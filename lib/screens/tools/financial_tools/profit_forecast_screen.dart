import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class ProfitForecastScreen extends StatefulWidget {
  const ProfitForecastScreen({Key? key}) : super(key: key);

  @override
  State<ProfitForecastScreen> createState() => _ProfitForecastScreenState();
}

class _ProfitForecastScreenState extends State<ProfitForecastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _initialRevenueController = TextEditingController(text: '10000');
  final _revenueGrowthController = TextEditingController(text: '5');
  final _initialCostController = TextEditingController(text: '7000');
  final _costGrowthController = TextEditingController(text: '3');

  Business? _selectedBusiness;
  int _forecastMonths = 12;
  bool _isLoading = false;
  bool _isForecastGenerated = false;

  List<Map<String, dynamic>> _forecastData = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      setState(() {
        _selectedBusiness = businessProvider.selectedBusiness ?? (businessProvider.businesses.isNotEmpty ? businessProvider.businesses[0] : null);
      });
    });
  }

  @override
  void dispose() {
    _initialRevenueController.dispose();
    _revenueGrowthController.dispose();
    _initialCostController.dispose();
    _costGrowthController.dispose();
    super.dispose();
  }

  void _generateForecast() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final initialRevenue = double.parse(_initialRevenueController.text);
      final revenueGrowth = double.parse(_revenueGrowthController.text) / 100;
      final initialCost = double.parse(_initialCostController.text);
      final costGrowth = double.parse(_costGrowthController.text) / 100;

      final today = DateTime.now();
      final forecastData = <Map<String, dynamic>>[];

      double currentRevenue = initialRevenue;
      double currentCost = initialCost;

      for (int i = 0; i < _forecastMonths; i++) {
        final month = DateTime(today.year, today.month + i, 1);
        final monthName = DateFormat('MMM yyyy').format(month);

        final revenue = currentRevenue;
        final cost = currentCost;
        final profit = revenue - cost;

        forecastData.add({'month': monthName, 'revenue': revenue, 'cost': cost, 'profit': profit});

        // Apply growth rates for next month
        currentRevenue += currentRevenue * revenueGrowth;
        currentCost += currentCost * costGrowth;
      }

      setState(() {
        _forecastData = forecastData;
        _isLoading = false;
        _isForecastGenerated = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      Helpers.showSnackBar(context, 'Error generating forecast: $e', isError: true);
    }
  }

  void _resetForm() {
    setState(() {
      _initialRevenueController.text = '10000';
      _revenueGrowthController.text = '5';
      _initialCostController.text = '7000';
      _costGrowthController.text = '3';
      _forecastMonths = 12;
      _forecastData = [];
      _isForecastGenerated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Profit Forecast', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(child: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: _isForecastGenerated ? _buildForecastResults(isDarkMode) : _buildForecastForm(isDarkMode, businessProvider))),
    );
  }

  Widget _buildForecastForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business selection
          Text('Business', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Business>(
                value: _selectedBusiness,
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                hint: Text('Select Business', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45)),
                items:
                    businessProvider.businesses.map((Business business) {
                      return DropdownMenuItem<Business>(value: business, child: Text(business.name));
                    }).toList(),
                onChanged: (Business? value) {
                  setState(() {
                    _selectedBusiness = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Revenue section
          Text('Revenue Projections', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),

          // Initial revenue
          Text('Initial Monthly Revenue (R)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _initialRevenueController,
            hintText: 'Enter initial revenue',
            prefixIcon: Icons.attach_money,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter initial revenue';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Revenue growth rate
          Text('Monthly Revenue Growth Rate (%)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _revenueGrowthController,
            hintText: 'Enter revenue growth rate',
            prefixIcon: Icons.trending_up,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter revenue growth rate';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Cost section
          Text('Cost Projections', style: AppStyles.h3(isDarkMode: isDarkMode)),
          const SizedBox(height: 16),

          // Initial cost
          Text('Initial Monthly Cost (R)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _initialCostController,
            hintText: 'Enter initial cost',
            prefixIcon: Icons.money_off,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter initial cost';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Cost growth rate
          Text('Monthly Cost Growth Rate (%)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _costGrowthController,
            hintText: 'Enter cost growth rate',
            prefixIcon: Icons.trending_up,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter cost growth rate';
              }
              if (double.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Forecast period
          Text('Forecast Period (Months)', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Slider(
            value: _forecastMonths.toDouble(),
            min: 3,
            max: 36,
            divisions: 33,
            label: _forecastMonths.toString(),
            onChanged: (value) {
              setState(() {
                _forecastMonths = value.toInt();
              });
            },
            activeColor: AppColors.primaryColor,
          ),
          Center(child: Text('$_forecastMonths months', style: TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(height: 32),

          // Generate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Generate Forecast', icon: Icons.auto_graph, onPressed: _generateForecast, type: ButtonType.primary)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildForecastResults(bool isDarkMode) {
    // Calculate cumulative profit
    double cumulativeProfit = 0;
    for (var data in _forecastData) {
      cumulativeProfit += data['profit'] as double;
    }

    // Find max and min profit for chart scaling
    double maxProfit = _forecastData.map((e) => e['profit'] as double).reduce((a, b) => a > b ? a : b);
    double minProfit = _forecastData.map((e) => e['profit'] as double).reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        // Profit chart
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxProfit / 5,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: isDarkMode ? Colors.white24 : Colors.black12, strokeWidth: 1);
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(color: isDarkMode ? Colors.white24 : Colors.black12, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: _forecastData.length > 12 ? 3 : 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= _forecastData.length || value.toInt() < 0) {
                        return const SizedBox();
                      }
                      final month = _forecastData[value.toInt()]['month'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          month.substring(0, 3), // Just show month abbreviation
                          style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxProfit / 5,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text('R${value.toInt()}', style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white70 : Colors.black54));
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
              minX: 0,
              maxX: _forecastData.length.toDouble() - 1,
              minY: minProfit < 0 ? minProfit * 1.1 : 0,
              maxY: maxProfit * 1.1,
              lineBarsData: [
                // Revenue line
                LineChartBarData(
                  spots:
                      _forecastData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['revenue'] as double);
                      }).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                ),
                // Cost line
                LineChartBarData(
                  spots:
                      _forecastData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['cost'] as double);
                      }).toList(),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                ),
                // Profit line
                LineChartBarData(
                  spots:
                      _forecastData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value['profit'] as double);
                      }).toList(),
                  isCurved: true,
                  color: AppColors.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppColors.primaryColor.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [_buildLegendItem('Revenue', Colors.green, isDarkMode), const SizedBox(width: 16), _buildLegendItem('Costs', Colors.red, isDarkMode), const SizedBox(width: 16), _buildLegendItem('Profit', AppColors.primaryColor, isDarkMode)],
          ),
        ),

        const SizedBox(height: 16),

        // Summary
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Forecast summary
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: isDarkMode ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Forecast Summary', style: AppStyles.h3(isDarkMode: isDarkMode)),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Forecast Period', '$_forecastMonths months', isDarkMode),
                      _buildSummaryRow('First Month Profit', 'R${_forecastData.first['profit'].toStringAsFixed(2)}', isDarkMode),
                      _buildSummaryRow('Last Month Profit', 'R${_forecastData.last['profit'].toStringAsFixed(2)}', isDarkMode),
                      _buildSummaryRow('Profit Growth', '${((_forecastData.last['profit'] / _forecastData.first['profit'] - 1) * 100).toStringAsFixed(2)}%', isDarkMode),
                      _buildSummaryRow('Cumulative Profit', 'R${cumulativeProfit.toStringAsFixed(2)}', isDarkMode, isHighlighted: true),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Monthly breakdown
                Text('Monthly Breakdown', style: AppStyles.h3(isDarkMode: isDarkMode)),
                const SizedBox(height: 16),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _forecastData.length,
                  itemBuilder: (context, index) {
                    final data = _forecastData[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [Text(data['month'] as String, style: TextStyle(fontWeight: FontWeight.bold)), Text('R${(data['profit'] as double).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: (data['profit'] as double) >= 0 ? Colors.green : Colors.red))],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Revenue', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)), Text('R${(data['revenue'] as double).toStringAsFixed(2)}', style: TextStyle(color: Colors.green))]),
                              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Costs', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)), Text('R${(data['cost'] as double).toStringAsFixed(2)}', style: TextStyle(color: Colors.red))]),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: Row(children: [Expanded(child: CustomButton(text: 'New Forecast', icon: Icons.refresh, onPressed: _resetForm, type: ButtonType.primary))]),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color, bool isDarkMode) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54))]);
  }

  Widget _buildSummaryRow(String label, String value, bool isDarkMode, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54)), Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isHighlighted ? 18 : 14, color: isHighlighted ? AppColors.primaryColor : null))],
      ),
    );
  }
}
