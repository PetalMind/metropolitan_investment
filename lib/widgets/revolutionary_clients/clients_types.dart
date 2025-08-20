/// 🔧 REVOLUTIONARY CLIENTS TYPES
///
/// Definicje typów używanych w systemie rewolucyjnych klientów
/// Współdzielone między wszystkimi komponentami

import 'package:flutter/material.dart';

/// Client filter options
enum ClientFilter {
  premium,
  corporate,
  inactive,
  recentActivity,
  highValue,
  lowRisk,
  highRisk,
  newClients,
  loyalClients,
}

/// Client sorting modes
enum ClientSortMode {
  name,
  value,
  lastActivity,
  riskScore,
  dateAdded,
  alphabetical,
  investmentCount,
}

/// Client view modes
enum ClientViewMode { grid, list, cards, timeline, compact, detailed }

/// Insight types for AI analytics
enum InsightType { opportunity, warning, info, success }

/// Insight priority levels
enum InsightPriority { low, medium, high, critical }

/// Client insight data class
class ClientInsight {
  final InsightType type;
  final String title;
  final String description;
  final InsightPriority priority;
  final bool actionable;
  final String? actionText;
  final VoidCallback? onAction;

  ClientInsight({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    this.actionable = false,
    this.actionText,
    this.onAction,
  });
}

/// Client metrics for analytics
class ClientMetrics {
  final double totalValue;
  final int investmentCount;
  final double averageInvestment;
  final DateTime lastActivity;
  final double riskScore;
  final double growthRate;
  final String tier;

  ClientMetrics({
    required this.totalValue,
    required this.investmentCount,
    required this.averageInvestment,
    required this.lastActivity,
    required this.riskScore,
    this.growthRate = 0.0,
    this.tier = 'Standard',
  });
}

/// Client statistics for dashboard
class ClientStats {
  final int totalClients;
  final int activeClients;
  final int premiumClients;
  final int corporateClients;
  final double averagePortfolioValue;
  final double totalAUM;
  final double monthlyGrowth;
  final DateTime lastUpdated;

  ClientStats({
    required this.totalClients,
    required this.activeClients,
    required this.premiumClients,
    required this.corporateClients,
    required this.averagePortfolioValue,
    required this.totalAUM,
    required this.monthlyGrowth,
    required this.lastUpdated,
  });
}

/// Loading progress data
class LoadingProgress {
  final double progress;
  final String message;
  final String stage;

  LoadingProgress({
    required this.progress,
    required this.message,
    required this.stage,
  });
}

/// Client selection data
class ClientSelection {
  final Set<String> selectedIds;
  final bool isSelectAll;
  final int totalCount;

  ClientSelection({
    required this.selectedIds,
    this.isSelectAll = false,
    this.totalCount = 0,
  });

  bool get hasSelection => selectedIds.isNotEmpty;
  int get selectedCount => selectedIds.length;

  ClientSelection copyWith({
    Set<String>? selectedIds,
    bool? isSelectAll,
    int? totalCount,
  }) {
    return ClientSelection(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectAll: isSelectAll ?? this.isSelectAll,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Search suggestions for AI search
class SearchSuggestion {
  final String text;
  final String category;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  SearchSuggestion({
    required this.text,
    required this.category,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

/// Filter chip data
class FilterChip {
  final ClientFilter filter;
  final String label;
  final IconData icon;
  final Color color;
  final bool isActive;
  final int count;

  FilterChip({
    required this.filter,
    required this.label,
    required this.icon,
    required this.color,
    this.isActive = false,
    this.count = 0,
  });
}

/// Animation configuration
class AnimationConfig {
  final Duration duration;
  final Curve curve;
  final Duration delay;

  const AnimationConfig({
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.delay = Duration.zero,
  });

  static const staggered = AnimationConfig(
    duration: Duration(milliseconds: 150),
    curve: Curves.easeOutBack,
  );

  static const hero = AnimationConfig(
    duration: Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
  );

  static const morphing = AnimationConfig(
    duration: Duration(milliseconds: 400),
    curve: Curves.easeInOutCubic,
  );
}

/// Action button configuration
class ActionButton {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool requiresConfirmation;

  ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.isDestructive = false,
    this.requiresConfirmation = false,
  });
}

/// Bulk action configuration
class BulkAction {
  final String label;
  final IconData icon;
  final Color color;
  final Function(List<String> clientIds) onExecute;
  final bool requiresConfirmation;
  final String? confirmationMessage;

  BulkAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onExecute,
    this.requiresConfirmation = false,
    this.confirmationMessage,
  });
}
