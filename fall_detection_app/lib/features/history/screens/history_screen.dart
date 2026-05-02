import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../shared/models/fall_event.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseService _firebase = FirebaseService();
  List<FallEvent> _events = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final events = await _firebase.getFallHistory();
    if (mounted) {
      setState(() {
        _events = events;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        title: const Text(
          'Fall History',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _loading = true);
              _loadHistory();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: AppColors.accent),
                      const SizedBox(height: 16),
                      const Text(
                        'No falls detected yet!',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'System is monitoring actively',
                        style: TextStyle(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      final event = _events[index];
                      return _FallEventCard(event: event);
                    },
                  ),
                ),
    );
  }
}

class _FallEventCard extends StatelessWidget {
  final FallEvent event;
  const _FallEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${event.timestamp.day}/${event.timestamp.month}/${event.timestamp.year} '
                  '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
                if (event.metric != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.metric!,
                    style: TextStyle(
                      color: AppColors.blueFg,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}