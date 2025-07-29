import 'package:flutter/material.dart';
import '../cache_debug_widget.dart';

class DashboardCacheDebugTab extends StatelessWidget {
  final bool isMobile;

  const DashboardCacheDebugTab({super.key, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: const Column(children: [CacheDebugWidget()]),
    );
  }
}
