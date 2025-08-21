import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

/// Professional shimmer loading widget with animated gradient effect
/// Specialized for premium analytics data loading states
class PremiumShimmerLoadingWidget extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final ShimmerType type;

  const PremiumShimmerLoadingWidget({
    super.key,
    this.height,
    this.width,
    this.borderRadius,
    this.margin,
    this.padding,
    this.type = ShimmerType.container,
  });

  /// Analytics cards shimmer for dashboard grid
  const PremiumShimmerLoadingWidget.analyticsCard({
    super.key,
    this.height = 120,
    this.width = double.infinity,
    this.margin = const EdgeInsets.all(8.0),
    this.padding,
    this.borderRadius,
  }) : type = ShimmerType.analyticsCard;

  /// List item shimmer for investor lists
  const PremiumShimmerLoadingWidget.listItem({
    super.key,
    this.height = 80,
    this.width = double.infinity,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
    this.padding,
    this.borderRadius,
  }) : type = ShimmerType.listItem;

  /// Table row shimmer for data tables
  const PremiumShimmerLoadingWidget.tableRow({
    super.key,
    this.height = 60,
    this.width = double.infinity,
    this.margin = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
    this.padding,
    this.borderRadius,
  }) : type = ShimmerType.tableRow;

  /// Chart placeholder shimmer
  const PremiumShimmerLoadingWidget.chart({
    super.key,
    this.height = 200,
    this.width = double.infinity,
    this.margin = const EdgeInsets.all(16.0),
    this.padding,
    this.borderRadius,
  }) : type = ShimmerType.chart;

  /// Full screen shimmer with multiple sections
  const PremiumShimmerLoadingWidget.fullScreen({
    super.key,
    this.height,
    this.width,
    this.margin,
    this.padding,
    this.borderRadius,
  }) : type = ShimmerType.fullScreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      width: width,
      margin: margin,
      padding: padding,
      child: Shimmer.fromColors(
        baseColor: isDark
            ? AppTheme.surfaceCard.withOpacity(0.3)
            : Colors.grey[300]!,
        highlightColor: isDark
            ? AppTheme.secondaryGold.withOpacity(0.1)
            : Colors.grey[100]!,
        period: const Duration(milliseconds: 1500),
        child: _buildShimmerContent(context),
      ),
    );
  }

  Widget _buildShimmerContent(BuildContext context) {
    switch (type) {
      case ShimmerType.analyticsCard:
        return _buildAnalyticsCardShimmer();
      case ShimmerType.listItem:
        return _buildListItemShimmer();
      case ShimmerType.tableRow:
        return _buildTableRowShimmer();
      case ShimmerType.chart:
        return _buildChartShimmer();
      case ShimmerType.fullScreen:
        return _buildFullScreenShimmer();
      case ShimmerType.container:
        return _buildContainerShimmer();
    }
  }

  Widget _buildAnalyticsCardShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and title row
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 100,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Value
          Container(
            width: 120,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItemShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          // Action
          Container(
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRowShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // First column
          Expanded(
            flex: 3,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Second column
          Expanded(
            flex: 2,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Third column
          Expanded(
            flex: 2,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Actions
          Container(
            width: 80,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: Border.all(color: AppTheme.secondaryGold.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart title
          Container(
            width: 150,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          // Chart area
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final heights = [60, 80, 45, 90, 70, 55, 85];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: heights[index].toDouble(),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenShimmer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Stats grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const PremiumShimmerLoadingWidget.analyticsCard();
            },
          ),
          const SizedBox(height: 24),
          // Chart
          const PremiumShimmerLoadingWidget.chart(),
          const SizedBox(height: 24),
          // List items
          ...List.generate(5, (index) {
            return const PremiumShimmerLoadingWidget.listItem();
          }),
        ],
      ),
    );
  }

  Widget _buildContainerShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

enum ShimmerType {
  container,
  analyticsCard,
  listItem,
  tableRow,
  chart,
  fullScreen,
}

/// Shimmer container for complex layouts
class PremiumShimmerContainer extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const PremiumShimmerContainer({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return child;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor:
          baseColor ??
          (isDark ? AppTheme.surfaceCard.withOpacity(0.3) : Colors.grey[300]!),
      highlightColor:
          highlightColor ??
          (isDark
              ? AppTheme.secondaryGold.withOpacity(0.1)
              : Colors.grey[100]!),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Analytics-specific shimmer layouts
class AnalyticsShimmerLayouts {
  /// Creates a shimmer layout for investor analytics overview
  static Widget investorOverview() {
    return Column(
      children: [
        // Header stats
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return const PremiumShimmerLoadingWidget.analyticsCard();
          },
        ),
        const SizedBox(height: 24),
        // Charts row
        Row(
          children: [
            Expanded(
              child: const PremiumShimmerLoadingWidget.chart(height: 300),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: const PremiumShimmerLoadingWidget.chart(height: 300),
            ),
          ],
        ),
      ],
    );
  }

  /// Creates a shimmer layout for investor table
  static Widget investorTable() {
    return Column(
      children: [
        // Table header
        const PremiumShimmerLoadingWidget.tableRow(height: 50),
        const SizedBox(height: 8),
        // Table rows
        ...List.generate(8, (index) {
          return const PremiumShimmerLoadingWidget.tableRow();
        }),
      ],
    );
  }

  /// Creates a shimmer layout for majority analysis
  static Widget majorityAnalysis() {
    return Column(
      children: [
        // Summary cards
        Row(
          children: [
            Expanded(
              child: const PremiumShimmerLoadingWidget.analyticsCard(
                height: 100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: const PremiumShimmerLoadingWidget.analyticsCard(
                height: 100,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: const PremiumShimmerLoadingWidget.analyticsCard(
                height: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Chart
        const PremiumShimmerLoadingWidget.chart(height: 250),
        const SizedBox(height: 24),
        // Majority holders list
        ...List.generate(5, (index) {
          return const PremiumShimmerLoadingWidget.listItem(height: 120);
        }),
      ],
    );
  }
}
