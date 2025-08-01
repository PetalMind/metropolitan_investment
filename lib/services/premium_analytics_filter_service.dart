import 'package:cloud_functions/cloud_functions.dart';
import '../models/investor_summary.dart';
import '../models/client.dart';
import '../widgets/premium_analytics_filter_panel.dart';

/// 🔥 SERVICE PREMIUM ANALYTICS FILTERING
///
/// Integracja z Firebase Functions dla zaawansowanego filtrowania
/// i analityki Premium Analytics Dashboard

class PremiumAnalyticsFilterService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Pobiera filtrowane dane analityczne z serwera
  static Future<PremiumAnalyticsResult> getFilteredAnalytics({
    required PremiumAnalyticsFilter filter,
    String sortBy = 'viableCapital',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 250,
  }) async {
    try {
      final callable = _functions.httpsCallable('getFilteredInvestorAnalytics');

      final result = await callable.call({
        'searchQuery': filter.searchQuery,
        'votingStatusFilter': filter.votingStatusFilter?.name,
        'clientTypeFilter': filter.clientTypeFilter?.name,
        'minCapital': filter.minCapital,
        'maxCapital': filter.maxCapital == double.infinity
            ? null
            : filter.maxCapital,
        'minInvestmentCount': filter.minInvestmentCount,
        'maxInvestmentCount': filter.maxInvestmentCount,
        'showOnlyMajorityHolders': filter.showOnlyMajorityHolders,
        'showOnlyLargeInvestors': filter.showOnlyLargeInvestors,
        'showOnlyWithUnviableInvestments':
            filter.showOnlyWithUnviableInvestments,
        'includeActiveOnly': filter.includeActiveOnly,
        'requireHighDiversification': filter.requireHighDiversification,
        'recentActivityOnly': filter.recentActivityOnly,
        'sortBy': sortBy,
        'sortAscending': sortAscending,
        'page': page,
        'pageSize': pageSize,
      });

      return PremiumAnalyticsResult.fromMap(result.data);
    } catch (e) {
      throw Exception('Błąd podczas pobierania filtrowanych danych: $e');
    }
  }

  /// Pobiera sugestie wyszukiwania
  static Future<List<SearchSuggestion>> getSearchSuggestions({
    required String query,
    int limit = 10,
  }) async {
    try {
      final callable = _functions.httpsCallable('getSmartSearchSuggestions');

      final result = await callable.call({'query': query, 'limit': limit});

      final suggestions = (result.data['suggestions'] as List)
          .map((item) => SearchSuggestion.fromMap(item))
          .toList();

      return suggestions;
    } catch (e) {
      throw Exception('Błąd podczas pobierania sugestii: $e');
    }
  }

  /// Pobiera presety dashboardu
  static Future<List<DashboardPreset>> getDashboardPresets() async {
    try {
      final callable = _functions.httpsCallable('getAnalyticsDashboardPresets');

      final result = await callable.call();

      final presets = (result.data['presets'] as List)
          .map((item) => DashboardPreset.fromMap(item))
          .toList();

      return presets;
    } catch (e) {
      throw Exception('Błąd podczas pobierania presetów: $e');
    }
  }
}

/// 📊 KLASA WYNIKÓW PREMIUM ANALYTICS
class PremiumAnalyticsResult {
  final List<InvestorSummary> investors;
  final List<InvestorSummary> allFilteredInvestors;
  final int originalCount;
  final int filteredCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final PremiumAnalyticsMetrics analytics;
  final Map<String, dynamic> appliedFilters;
  final int executionTime;
  final String source;

  const PremiumAnalyticsResult({
    required this.investors,
    required this.allFilteredInvestors,
    required this.originalCount,
    required this.filteredCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.analytics,
    required this.appliedFilters,
    required this.executionTime,
    required this.source,
  });

  factory PremiumAnalyticsResult.fromMap(Map<String, dynamic> map) {
    return PremiumAnalyticsResult(
      investors: (map['investors'] as List)
          .map((item) => InvestorSummary.fromMap(item))
          .toList(),
      allFilteredInvestors: (map['allFilteredInvestors'] as List)
          .map((item) => InvestorSummary.fromMap(item))
          .toList(),
      originalCount: map['originalCount'] ?? 0,
      filteredCount: map['filteredCount'] ?? 0,
      currentPage: map['currentPage'] ?? 1,
      pageSize: map['pageSize'] ?? 250,
      totalPages: map['totalPages'] ?? 1,
      hasNextPage: map['hasNextPage'] ?? false,
      hasPreviousPage: map['hasPreviousPage'] ?? false,
      analytics: PremiumAnalyticsMetrics.fromMap(map['analytics'] ?? {}),
      appliedFilters: Map<String, dynamic>.from(map['appliedFilters'] ?? {}),
      executionTime: map['executionTime'] ?? 0,
      source: map['source'] ?? 'unknown',
    );
  }
}

/// 📈 KLASA METRYK PREMIUM ANALYTICS
class PremiumAnalyticsMetrics {
  final double totalCapital;
  final double originalCapital;
  final double capitalPercentage;
  final int investorCount;
  final int originalInvestorCount;
  final double investorPercentage;
  final Map<VotingStatus, VotingMetrics> votingDistribution;
  final CapitalDistribution capitalDistribution;
  final List<InvestorSummary> majorityHolders;
  final double averageCapital;
  final double medianCapital;
  final DiversificationStats diversificationStats;

  const PremiumAnalyticsMetrics({
    required this.totalCapital,
    required this.originalCapital,
    required this.capitalPercentage,
    required this.investorCount,
    required this.originalInvestorCount,
    required this.investorPercentage,
    required this.votingDistribution,
    required this.capitalDistribution,
    required this.majorityHolders,
    required this.averageCapital,
    required this.medianCapital,
    required this.diversificationStats,
  });

  factory PremiumAnalyticsMetrics.fromMap(Map<String, dynamic> map) {
    return PremiumAnalyticsMetrics(
      totalCapital: (map['totalCapital'] ?? 0).toDouble(),
      originalCapital: (map['originalCapital'] ?? 0).toDouble(),
      capitalPercentage: (map['capitalPercentage'] ?? 0).toDouble(),
      investorCount: map['investorCount'] ?? 0,
      originalInvestorCount: map['originalInvestorCount'] ?? 0,
      investorPercentage: (map['investorPercentage'] ?? 0).toDouble(),
      votingDistribution: _parseVotingDistribution(
        map['votingDistribution'] ?? {},
      ),
      capitalDistribution: CapitalDistribution.fromMap(
        map['capitalDistribution'] ?? {},
      ),
      majorityHolders: (map['majorityHolders'] as List? ?? [])
          .map((item) => InvestorSummary.fromMap(item))
          .toList(),
      averageCapital: (map['averageCapital'] ?? 0).toDouble(),
      medianCapital: (map['medianCapital'] ?? 0).toDouble(),
      diversificationStats: DiversificationStats.fromMap(
        map['diversificationStats'] ?? {},
      ),
    );
  }

  static Map<VotingStatus, VotingMetrics> _parseVotingDistribution(
    Map<String, dynamic> map,
  ) {
    final result = <VotingStatus, VotingMetrics>{};

    for (final status in VotingStatus.values) {
      final statusData = map[status.name] ?? {};
      result[status] = VotingMetrics(
        count: statusData['count'] ?? 0,
        capital: (statusData['capital'] ?? 0).toDouble(),
      );
    }

    return result;
  }
}

/// 🗳️ KLASA METRYK GŁOSOWANIA
class VotingMetrics {
  final int count;
  final double capital;

  const VotingMetrics({required this.count, required this.capital});
}

/// 💰 KLASA DYSTRYBUCJI KAPITAŁU
class CapitalDistribution {
  final int small; // < 100K
  final int medium; // 100K - 1M
  final int large; // > 1M

  const CapitalDistribution({
    required this.small,
    required this.medium,
    required this.large,
  });

  factory CapitalDistribution.fromMap(Map<String, dynamic> map) {
    return CapitalDistribution(
      small: map['small'] ?? 0,
      medium: map['medium'] ?? 0,
      large: map['large'] ?? 0,
    );
  }

  int get total => small + medium + large;
}

/// 🎯 KLASA STATYSTYK DYWERSYFIKACJI
class DiversificationStats {
  final double averageProducts;
  final int highlyDiversified;
  final double diversificationPercentage;

  const DiversificationStats({
    required this.averageProducts,
    required this.highlyDiversified,
    required this.diversificationPercentage,
  });

  factory DiversificationStats.fromMap(Map<String, dynamic> map) {
    return DiversificationStats(
      averageProducts: (map['averageProducts'] ?? 0).toDouble(),
      highlyDiversified: map['highlyDiversified'] ?? 0,
      diversificationPercentage: (map['diversificationPercentage'] ?? 0)
          .toDouble(),
    );
  }
}

/// 🔍 KLASA SUGESTII WYSZUKIWANIA
class SearchSuggestion {
  final String type;
  final String value;
  final String label;
  final String category;

  const SearchSuggestion({
    required this.type,
    required this.value,
    required this.label,
    required this.category,
  });

  factory SearchSuggestion.fromMap(Map<String, dynamic> map) {
    return SearchSuggestion(
      type: map['type'] ?? '',
      value: map['value'] ?? '',
      label: map['label'] ?? '',
      category: map['category'] ?? '',
    );
  }
}

/// 📋 KLASA PRESETÓW DASHBOARDU
class DashboardPreset {
  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> filters;
  final String icon;

  const DashboardPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.filters,
    required this.icon,
  });

  factory DashboardPreset.fromMap(Map<String, dynamic> map) {
    return DashboardPreset(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      filters: Map<String, dynamic>.from(map['filters'] ?? {}),
      icon: map['icon'] ?? '📊',
    );
  }

  PremiumAnalyticsFilter toFilter() {
    final filter = PremiumAnalyticsFilter();

    // Apply filters from preset
    if (filters.containsKey('votingStatusFilter')) {
      filter.votingStatusFilter = VotingStatus.values
          .where((s) => s.name == filters['votingStatusFilter'])
          .firstOrNull;
    }

    if (filters.containsKey('showOnlyMajorityHolders')) {
      filter.showOnlyMajorityHolders =
          filters['showOnlyMajorityHolders'] ?? false;
    }

    if (filters.containsKey('showOnlyLargeInvestors')) {
      filter.showOnlyLargeInvestors =
          filters['showOnlyLargeInvestors'] ?? false;
    }

    if (filters.containsKey('minCapital')) {
      filter.minCapital = (filters['minCapital'] ?? 0).toDouble();
    }

    if (filters.containsKey('maxCapital')) {
      filter.maxCapital = (filters['maxCapital'] ?? double.infinity).toDouble();
    }

    if (filters.containsKey('includeActiveOnly')) {
      filter.includeActiveOnly = filters['includeActiveOnly'] ?? false;
    }

    if (filters.containsKey('showOnlyWithUnviableInvestments')) {
      filter.showOnlyWithUnviableInvestments =
          filters['showOnlyWithUnviableInvestments'] ?? false;
    }

    if (filters.containsKey('requireHighDiversification')) {
      filter.requireHighDiversification =
          filters['requireHighDiversification'] ?? false;
    }

    if (filters.containsKey('recentActivityOnly')) {
      filter.recentActivityOnly = filters['recentActivityOnly'] ?? false;
    }

    if (filters.containsKey('minInvestmentCount')) {
      filter.minInvestmentCount = filters['minInvestmentCount'] ?? 0;
    }

    return filter;
  }
}
