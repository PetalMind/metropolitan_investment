// Models exports
export 'models/client.dart';
export 'models/client_note.dart';
export 'models/employee.dart';
export 'models/investment.dart'; // 🚀 UPDATED: Enhanced with normalized JSON field mapping (productId, capitalSecuredByRealEstate, capitalForRestructuring)
export 'models/product.dart';
export 'models/company.dart';
export 'models/bond.dart';
export 'models/loan.dart';
export 'models/share.dart';
export 'models/apartment.dart';
export 'models/unified_product.dart';
export 'models/investor_summary.dart'; // 🚀 NOWE: InvestorSummary.withoutCalculations() + calculateSecuredCapitalForAll()
export 'models/excel_import_models.dart';
export 'models/voting_status_change.dart';
export 'models/investment_change_history.dart'; // 🚀 NOWE: Historia zmian inwestycji
export 'models/investor_edit_models.dart'; // 🚀 NOWE: Modele dla edycji inwestora

// Analytics models exports
export 'models/analytics/overview_analytics_models.dart';

// Services exports
export 'services/base_service.dart';
export 'services/data_cache_service.dart'; // 🚀 DODANE: Serwis cache'owania danych
export 'services/client_service.dart';
export 'services/firebase_functions_client_service.dart' show ClientStats;
export 'services/integrated_client_service.dart';
export 'services/client_notes_service.dart';
export 'services/client_id_mapping_service.dart';
export 'services/enhanced_client_id_mapping_service.dart';
export 'services/employee_service.dart';
export 'services/investment_service.dart'; // 🚀 UPDATED: Enhanced support for normalized JSON data import with logical IDs
export 'services/product_service.dart';
export 'services/company_service.dart';
export 'services/unified_product_service.dart';
export 'services/enhanced_unified_product_service.dart';
export 'services/deduplicated_product_service.dart';
export 'services/optimized_product_service.dart'; // 🚀 NOWE: Zoptymalizowany serwis produktów (batch)
export 'services/product_management_service.dart'
    hide
        ProductTypeStats,
        ProductDetails; // 🚀 CENTRALNY: Unified service zarządzający produktami
export 'services/cache_management_service.dart'; // 🚀 CENTRALNY: Zarządzanie cache wszystkich serwisów
export 'services/firebase_functions_data_service.dart'
    hide
        ClientsResult; // 🚀 UPDATED: Enhanced Firebase Functions integration with normalized field mapping
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
export 'services/auth_service.dart';
export 'services/email_service.dart';
export 'services/email_and_export_service.dart'; // 🚀 NOWE: Email i eksport danych
export 'services/user_preferences_service.dart';
export 'services/advanced_analytics_service.dart' hide AdvancedDashboardMetrics;
export 'services/investor_analytics_service.dart' hide InvestorAnalyticsResult;
export 'services/standard_product_investors_service.dart';

// 🚀 OPTIMIZED SERVICES - Migracja na optymalne obliczenia
// Te serwisy teraz używają InvestorSummary.withoutCalculations() + calculateSecuredCapitalForAll()
// zamiast obliczeń dla każdego klienta osobno w InvestorSummary.fromInvestments()
//
// ⭐ NOWA ARCHITEKTURA DANYCH (Styczeń 2025):
// - Unified investments collection z logicznymi ID (bond_0001, loan_0005, etc.)
// - Enhanced field mapping: English property names ↔ Polish Firebase field names
// - Normalized JSON import support with apartment ID generation
// - Backward compatibility with legacy field names maintained
//
// Korzyści:
// - Obliczenia wykonują się TYLKO RAZ na końcu dla wszystkich zsumowanych kwot
// - Eliminuje redundantne obliczenia capitalSecuredByRealEstate dla każdego inwestora
// - Lepsze zgodność z wzorem: capitalSecured = sum(remainingCapital) - sum(capitalForRestructuring)
// - Jednolita kolekcja investments zamiast oddzielnych kolekcji bonds/loans/shares/apartments

// New voting and analytics services - UNIFIED VERSION
export 'services/unified_voting_status_service.dart';
export 'services/unified_statistics_utils.dart';
export 'services/unified_statistics_service.dart'; // ZUNIFIKOWANY SERWIS (lokalny fallback)
export 'services/server_side_statistics_service.dart'; // 🚀 SERWIS SERWEROWY (Firebase Functions)
export 'services/unified_dashboard_statistics_service.dart'; // 🚀 NOWE: Zunifikowane statystyki dashboard
export 'services/debug_firestore_service.dart';
export 'services/investment_change_history_service.dart'; // 🚀 NOWE: Historia zmian inwestycji
export 'services/investor_edit_service.dart'; // 🚀 NOWE: Serwis logiki biznesowej dla edycji inwestora

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

// Legacy services (deprecated - will be replaced by unified investments collection)
// These services work with separate collections: bonds, loans, shares, apartments
// 🎯 MIGRATION NOTE: Data is being consolidated into 'investments' collection
// with logical IDs like bond_0001, loan_0005, share_0123, apartment_0045
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

// Dialog widgets
export 'widgets/dialogs/investor_edit_dialog.dart'; // ⭐ NOWE: Dialog edycji inwestora (refaktoryzowany)
export 'widgets/dialogs/investor_email_dialog.dart'; // ⭐ NOWE: Dialog wysyłania maili
export 'widgets/dialogs/investor_export_dialog.dart'; // ⭐ NOWE: Dialog eksportu danych

// Investor Edit Components - UI Components for editing investors
export 'widgets/investor_edit/currency_controls.dart'; // 🚀 NOWE: Kontrolki walutowe
export 'widgets/investor_edit/investments_summary.dart'; // 🚀 NOWE: Podsumowanie inwestycji
export 'widgets/investor_edit/investment_edit_card.dart'; // 🚀 NOWE: Karta edycji inwestycji

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
export 'utils/currency_input_formatter.dart'; // 🚀 NOWE: Formatter dla pól walutowych
export 'utils/cache_helper.dart'; // 🚀 HELPER: Łatwe zarządzanie cache w UI
export 'utils/voting_analysis_manager.dart';
export 'utils/investor_sort_filter_manager.dart';
export 'utils/pagination_manager.dart';
