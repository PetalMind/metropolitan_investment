import 'package:flutter/material.dart';
import '../../models_and_services.dart';
import '../../theme/app_theme_professional.dart';

/// Prosty grid klientów bez animacji - dla zwykłych klientów
class SimpleClientsGrid extends StatefulWidget {
  final List<Client> clients;
  final bool isLoading;
  final bool isSelectionMode;
  final Set<String> selectedClientIds;
  final ScrollController? scrollController;
  final Function(Client)? onClientTap;
  final Function(Set<String>)? onSelectionChanged;
  final Function()? onLoadMore;
  final bool hasMoreData;
  final Map<String, InvestorSummary> investorSummaries;
  final Map<String, List<Investment>> clientInvestments;

  const SimpleClientsGrid({
    super.key,
    required this.clients,
    required this.isLoading,
    required this.isSelectionMode,
    required this.selectedClientIds,
    this.scrollController,
    this.onClientTap,
    this.onSelectionChanged,
    this.onLoadMore,
    required this.hasMoreData,
    required this.investorSummaries,
    required this.clientInvestments,
  });

  @override
  State<SimpleClientsGrid> createState() => _SimpleClientsGridState();
}

class _SimpleClientsGridState extends State<SimpleClientsGrid> {
  @override
  Widget build(BuildContext context) {
    if (widget.clients.isEmpty) {
      return const Center(
        child: Text(
          'Brak klientów do wyświetlenia',
          style: TextStyle(color: AppThemePro.textSecondary),
        ),
      );
    }

    return GridView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.clients.length + (widget.hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.clients.length) {
          // Load more indicator
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final client = widget.clients[index];
        final isSelected = widget.selectedClientIds.contains(client.id);
        final investorSummary = widget.investorSummaries[client.id];
        final investments = widget.clientInvestments[client.id] ?? [];

        return _buildClientCard(client, isSelected, investorSummary, investments);
      },
    );
  }

  Widget _buildClientCard(
    Client client,
    bool isSelected,
    InvestorSummary? investorSummary,
    List<Investment> investments,
  ) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected
          ? AppThemePro.accentGold.withOpacity(0.1)
          : AppThemePro.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppThemePro.accentGold : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: widget.isSelectionMode
            ? () => _toggleSelection(client.id)
            : () => widget.onClientTap?.call(client),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header z nazwą i checkbox/selection indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppThemePro.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleSelection(client.id),
                      activeColor: AppThemePro.accentGold,
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Email
              if (client.email.isNotEmpty)
                Text(
                  client.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppThemePro.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 4),

              // Phone
              if (client.phone.isNotEmpty)
                Text(
                  client.phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppThemePro.textSecondary,
                  ),
                  maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                ),

              const Spacer(),

              // Investment summary
              if (investorSummary != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppThemePro.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${investorSummary.investmentCount} inwestycji',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppThemePro.textSecondary,
                        ),
                      ),
                      Text(
                        '${investorSummary.totalRemainingCapital.toStringAsFixed(0)} PLN',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppThemePro.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: client.isActive
                      ? AppThemePro.statusSuccess.withOpacity(0.2)
                      : AppThemePro.statusError.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  client.isActive ? 'Aktywny' : 'Nieaktywny',
                  style: TextStyle(
                    fontSize: 10,
                    color: client.isActive
                        ? AppThemePro.statusSuccess
                        : AppThemePro.statusError,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String clientId) {
    final newSelection = Set<String>.from(widget.selectedClientIds);
    if (newSelection.contains(clientId)) {
      newSelection.remove(clientId);
    } else {
      newSelection.add(clientId);
    }
    widget.onSelectionChanged?.call(newSelection);
  }
}
