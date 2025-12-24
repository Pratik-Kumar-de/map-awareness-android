import 'package:flutter/material.dart';
import 'package:map_awareness/routing.dart';

/// Displays a collapsible summary of roadworks on a route.
class RoadworksSummary extends StatelessWidget {
  // [ongoing, shortTerm, future]
  final List<List<RoutingWidgetData>> roadworks;

  const RoadworksSummary({super.key, required this.roadworks});

  @override
  Widget build(BuildContext context) {
    final total = roadworks[0].length + roadworks[1].length + roadworks[2].length;
    // Combine all roadworks with their category colors
    final all = [
      ...roadworks[0].map((r) => (r, Colors.orange)),
      ...roadworks[1].map((r) => (r, Colors.amber)),
      ...roadworks[2].map((r) => (r, Colors.blue)),
    ];
    
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.construction, color: Colors.orange),
        title: Text('$total Roadworks on Route'),
        subtitle: Text(
          '${roadworks[0].length} ongoing • ${roadworks[1].length} short-term • ${roadworks[2].length} future',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: all.map((item) => RoadworkTile(data: item.$1, color: item.$2)).toList(),
      ),
    );
  }
}

/// Displays a single roadwork item.
class RoadworkTile extends StatelessWidget {
  final RoutingWidgetData data;
  final Color color;

  const RoadworkTile({super.key, required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          data.typeLabel,
          style: TextStyle(
            fontSize: 10,
            color: HSLColor.fromColor(color).withLightness(0.3).toColor(),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(data.title, style: const TextStyle(fontSize: 13)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.subtitle.isNotEmpty)
            Text(data.subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (data.infoSummary.isNotEmpty)
            Text(data.infoSummary, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
      trailing: Text(
        data.time == 'ongoing' ? '⏱' : '📅 ${_formatTimestamp(data.time)}',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  /// Formats an ISO timestamp to a short date string.
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.day}.${dt.month}.${dt.year.toString().substring(2)}';
    } catch (e) {
      return timestamp;
    }
  }
}
