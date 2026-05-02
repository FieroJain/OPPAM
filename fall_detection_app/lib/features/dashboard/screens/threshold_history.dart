import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class ThresholdHistoryScreen extends StatefulWidget {
  const ThresholdHistoryScreen({super.key});

  @override
  State<ThresholdHistoryScreen> createState() => _ThresholdHistoryScreenState();
}

class _ThresholdHistoryScreenState extends State<ThresholdHistoryScreen> {
  final List<FlSpot> _thresholdPoints = [];
  final List<String> _timestamps = [];
  final List<String> _actions = [];
  StreamSubscription? _subscription;
  double _currentThreshold = 2.5;
  String _currentAction = 'HOLD';
  int _sampleCount = 0;

  // Color scheme matching app dark theme
  static const Color _bg = Color(0xFF0A0E1A);
  static const Color _card = Color(0xFF131929);
  static const Color _accent = Color(0xFF00E5A0);
  static const Color _warning = Color(0xFFFFB347);
  static const Color _danger = Color(0xFFFF4B6E);
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFF8A9BB5);

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'MORE_SENSITIVE':
        return _danger;
      case 'RELAX':
        return _accent;
      default:
        return _warning;
    }
  }

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final ref = FirebaseDatabase.instance.ref('live');
    _subscription = ref.onValue.listen((event) {
      if (!event.snapshot.exists || !mounted) return;
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final thr = (data['rl_threshold'] ?? 2.5).toDouble();
        final action = (data['rl_action'] ?? 'HOLD').toString();
        final ts = (data['timestamp'] ?? '').toString();

        setState(() {
          _currentThreshold = thr;
          _currentAction = action;
          _sampleCount++;

          // Keep last 30 points
          if (_thresholdPoints.length >= 30) {
            _thresholdPoints.removeAt(0);
            _timestamps.removeAt(0);
            _actions.removeAt(0);
            for (int i = 0; i < _thresholdPoints.length; i++) {
              _thresholdPoints[i] = FlSpot(i.toDouble(), _thresholdPoints[i].y);
            }
          }
          _thresholdPoints.add(
              FlSpot(_thresholdPoints.length.toDouble(), thr));
          _timestamps.add(ts.length > 8 ? ts.substring(11, 19) : ts);
          _actions.add(action);
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'RL Threshold History',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _accent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status card
            _buildCurrentStatusCard(),
            const SizedBox(height: 20),
            // Chart
            _buildChart(),
            const SizedBox(height: 20),
            // Legend
            _buildLegend(),
            const SizedBox(height: 20),
            // What this means
            _buildExplanationCard(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final color = _actionColor(_currentAction);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.tune, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Threshold',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currentThreshold.toStringAsFixed(3)} g',
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _currentAction,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_sampleCount updates',
                style: TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_thresholdPoints.isEmpty) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, color: _textSecondary, size: 40),
              const SizedBox(height: 12),
              Text(
                'Waiting for data...',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'ESP32 must be connected and sending',
                style: TextStyle(color: _textSecondary.withOpacity(0.6), fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 16),
            child: Text(
              'Threshold over last ${_thresholdPoints.length} readings',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 1.5,
                maxY: 3.5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 0.5,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toStringAsFixed(1)}g',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                // Reference line at 2.5g (default)
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 2.5,
                      color: _textSecondary.withOpacity(0.3),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 9,
                        ),
                        labelResolver: (_) => 'default 2.5g',
                      ),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _thresholdPoints,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: _accent,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, index) {
                        final action = index < _actions.length
                            ? _actions[index]
                            : 'HOLD';
                        return FlDotCirclePainter(
                          radius: 3,
                          color: _actionColor(action),
                          strokeWidth: 1,
                          strokeColor: Colors.black,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _accent.withOpacity(0.2),
                          _accent.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _legendDot(_accent, 'RELAX (3.0g)'),
        const SizedBox(width: 20),
        _legendDot(_warning, 'HOLD (2.5g)'),
        const SizedBox(width: 20),
        _legendDot(_danger, 'MORE SENSITIVE'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: _textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: _accent, size: 18),
              const SizedBox(width: 8),
              const Text(
                'How RL Adaptation Works',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _explanationRow('RELAX → 3.0g',
              'Patient is calm — harder to trigger to reduce false alarms', _accent),
          const SizedBox(height: 8),
          _explanationRow('HOLD → 2.5g',
              'Normal activity — default sensitivity maintained', _warning),
          const SizedBox(height: 8),
          _explanationRow('MORE SENSITIVE → 2.0-2.2g',
              'Unusual movement detected — system becomes more alert', _danger),
        ],
      ),
    );
  }

  Widget _explanationRow(String title, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 3,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                desc,
                style: TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}