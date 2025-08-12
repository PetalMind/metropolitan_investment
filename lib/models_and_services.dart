// Models exports
export 'models/client.dart';
export 'models/client_note.dart';
export 'models/employee.dart';
export 'models/investment.dart';
export 'models/product.dart';
export 'models/company.dart';
export 'models/bond.dart';
export 'models/loan.dart';
export 'models/share.dart';
export 'models/apartment.dart';
export 'models/unified_product.dart';
export 'models/investor_summary.dart';
export 'models/excel_import_models.dart';
export 'models/voting_status_change.dart';

// Analytics models exports
export 'models/analytics/overview_analytics_models.dart';

// Services exports
export 'services/base_service.dart';
export 'services/client_service.dart';
export 'services/firebase_functions_client_service.dart' show ClientStats;
export 'services/integrated_client_service.dart';
export 'services/client_notes_service.dart';
export 'services/client_id_mapping_service.dart';
export 'services/enhanced_client_id_mapping_service.dart';
export 'services/employee_service.dart';
export 'services/investment_service.dart';
export 'services/product_service.dart';
export 'services/company_service.dart';
export 'services/unified_product_service.dart';
export 'services/enhanced_unified_product_service.dart';
export 'services/deduplicated_product_service.dart';
export 'services/firebase_functions_data_service.dart' hide ClientsResult;
export 'services/firebase_functions_products_service.dart'
    hide ProductStatistics;
export 'services/firebase_functions_product_investors_service.dart';
export 'services/firebase_functions_advanced_analytics_service.dart';
export 'services/firebase_functions_analytics_service_updated.dart'
    hide
        ClientsResult,
        ProductInvestorsResult,
        PaginationInfo,
        ProductTypeStatistics;
export 'services/firebase_functions_capital_calculation_service.dart';
export 'services/dashboard_service.dart';
export 'services/auth_service.dart';
export 'services/email_service.dart';
export 'services/user_preferences_service.dart';
export 'services/advanced_analytics_service.dart' hide AdvancedDashboardMetrics;
export 'services/investor_analytics_service.dart' hide InvestorAnalyticsResult;
export 'services/standard_product_investors_service.dart';

// New voting and analytics services - UNIFIED VERSION
export 'services/unified_voting_status_service.dart';
export 'services/unified_statistics_utils.dart';
export 'services/debug_firestore_service.dart';

// Voting status change model
// VotingStatusChange is exported via models/voting_status_change.dart above

// ⚠️ DEPRECATED SERVICES DISABLED DUE TO IMPORT CONFLICTS ⚠️
// These services have been replaced by UnifiedVotingStatusService
// All functionality is now available through the unified service
//
// If you need these services, use UnifiedVotingStatusService instead:
// - EnhancedVotingStatusService → UnifiedVotingStatusService
// - UnifiedVotingService → UnifiedVotingStatusService
// - VotingStatusChangeService → UnifiedVotingStatusService (except VotingStatusChangeRecord model)
//
// export 'services/enhanced_voting_status_service.dart' hide VotingStatusUpdateResult, VotingStatusStatistics;
// export 'services/unified_voting_service.dart';

// Legacy services (deprecated)
export 'services/bond_service.dart';
export 'services/loan_service.dart';
export 'services/share_service.dart';
export 'services/apartment_service.dart';

// Widget exports - Logo and branding components
export 'widgets/metropolitan_components.dart';
export 'widgets/investor_details_modal.dart';
export 'widgets/capital_calculation_management_screen.dart';
export 'widgets/capital_calculation_widgets.dart';
export 'widgets/client_dialog.dart';
export 'widgets/custom_loading_widget.dart';
export 'widgets/data_table_widget.dart';
export 'widgets/client_form.dart';
export 'widgets/client_stats_widget.dart';
export 'widgets/enhanced_client_stats_widget.dart';
export 'widgets/client_stats_demo.dart';
export 'widgets/client_stats_debug_widget.dart';

// Investor Analytics Widgets - Professional Financial Views
export 'widgets/investor_analytics/investor_views_container.dart';
export 'widgets/investor_analytics/investor_table_widget.dart';
export 'widgets/investor_analytics/investor_list_widget.dart';
export 'widgets/investor_analytics/investor_cards_widget.dart';
export 'widgets/investor_analytics/investor_export_helper.dart';

// Screen exports - DEPRECATED SCREENS REMOVED
// export 'screens/voting_system_demo.dart'; // Removed - demo no longer needed

// Theme exports
export 'theme/app_theme.dart';

// Utils exports
export 'utils/currency_formatter.dart';
export 'utils/voting_analysis_manager.dart';
export 'utils/investor_sort_filter_manager.dart';
export 'utils/pagination_manager.dart';
