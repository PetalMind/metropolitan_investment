import 'package:flutter/material.dart';
import '../models_and_services.dart';

/// Zoptymalizowany widget do zmiany statusu głosowania
/// Zgodny z wzorcami projektu Metropolitan Investment
class OptimizedVotingStatusSelector extends StatefulWidget {
  final VotingStatus currentStatus;
  final Function(VotingStatus) onStatusChanged;
  final bool isCompact;
  final bool showLabels;
  final String? clientName;
  final bool enabled; // RBAC: czy można edytować

  const OptimizedVotingStatusSelector({
    super.key,
    required this.currentStatus,
    required this.onStatusChanged,
    this.isCompact = false,
    this.showLabels = true,
    this.clientName,
    this.enabled = true, // domyślnie włączony
  });

  @override
  State<OptimizedVotingStatusSelector> createState() =>
      _OptimizedVotingStatusSelectorState();
}

class _OptimizedVotingStatusSelectorState
    extends State<OptimizedVotingStatusSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  VotingStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactSelector();
    } else {
      return _buildFullSelector();
    }
  }

  Widget _buildCompactSelector() {
    return PopupMenuButton<VotingStatus>(
      initialValue: _selectedStatus,
      onSelected: _handleStatusChange,
      itemBuilder: (context) => VotingStatus.values.map((status) {
        return PopupMenuItem<VotingStatus>(
          value: status,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getVotingStatusIcon(status),
                color: _getVotingStatusColor(status),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                status.displayName,
                style: TextStyle(
                  color: _getVotingStatusColor(status),
                  fontWeight: _selectedStatus == status
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              if (_selectedStatus == status) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check,
                  color: _getVotingStatusColor(status),
                  size: 16,
                ),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getVotingStatusColor(_selectedStatus!).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getVotingStatusColor(_selectedStatus!),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getVotingStatusIcon(_selectedStatus!),
              color: _getVotingStatusColor(_selectedStatus!),
              size: 16,
            ),
            if (widget.showLabels) ...[
              const SizedBox(width: 4),
              Text(
                _selectedStatus!.displayName,
                style: TextStyle(
                  color: _getVotingStatusColor(_selectedStatus!),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: _getVotingStatusColor(_selectedStatus!),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.clientName != null) ...[
          Text(
            'Status głosowania dla: ${widget.clientName}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Wybierz status głosowania:',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: VotingStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            return AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isSelected ? _scaleAnimation.value : 1.0,
                  child: Tooltip(
                    message: widget.enabled ? '' : kRbacNoPermissionTooltip,
                    child: GestureDetector(
                      onTap: widget.enabled
                          ? () => _handleStatusChange(status)
                          : null,
                      onTapDown: widget.enabled
                          ? (_) => _animationController.forward()
                          : null,
                      onTapUp: widget.enabled
                          ? (_) => _animationController.reverse()
                          : null,
                      onTapCancel: widget.enabled
                          ? () => _animationController.reverse()
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: !widget.enabled
                              ? Colors.grey.withOpacity(0.1)
                              : isSelected
                              ? _getVotingStatusColor(status)
                              : _getVotingStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: !widget.enabled
                                ? Colors.grey.shade400
                                : _getVotingStatusColor(status),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected && widget.enabled
                              ? [
                                  BoxShadow(
                                    color: _getVotingStatusColor(
                                      status,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getVotingStatusIcon(status),
                              color: !widget.enabled
                                  ? Colors.grey.shade600
                                  : isSelected
                                  ? Colors.white
                                  : _getVotingStatusColor(status),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              status.displayName,
                              style: TextStyle(
                                color: !widget.enabled
                                    ? Colors.grey.shade600
                                    : isSelected
                                    ? Colors.white
                                    : _getVotingStatusColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ), // Zamknięcie GestureDetector
                  ), // Zamknięcie Tooltip
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildStatusDescription(),
      ],
    );
  }

  Widget _buildStatusDescription() {
    final descriptions = {
      VotingStatus.yes: 'Klient zagłosuje "TAK" w głosowaniu',
      VotingStatus.no: 'Klient zagłosuje "NIE" w głosowaniu',
      VotingStatus.abstain: 'Klient wstrzyma się od głosu',
      VotingStatus.undecided: 'Status głosowania nie został ustalony',
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getVotingStatusColor(_selectedStatus!).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getVotingStatusColor(_selectedStatus!).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: _getVotingStatusColor(_selectedStatus!),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              descriptions[_selectedStatus!] ?? '',
              style: TextStyle(
                color: _getVotingStatusColor(_selectedStatus!),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleStatusChange(VotingStatus newStatus) {
    if (_selectedStatus != newStatus) {
      setState(() {
        _selectedStatus = newStatus;
      });

      // Wywołaj callback z lekkim opóźnieniem dla animacji
      Future.delayed(const Duration(milliseconds: 100), () {
        widget.onStatusChanged(newStatus);
      });
    }
  }

  IconData _getVotingStatusIcon(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Icons.check_circle;
      case VotingStatus.no:
        return Icons.cancel;
      case VotingStatus.abstain:
        return Icons.remove_circle;
      case VotingStatus.undecided:
        return Icons.help_outline;
    }
  }

  Color _getVotingStatusColor(VotingStatus status) {
    switch (status) {
      case VotingStatus.yes:
        return Colors.green;
      case VotingStatus.no:
        return Colors.red;
      case VotingStatus.abstain:
        return Colors.orange;
      case VotingStatus.undecided:
        return Colors.grey;
    }
  }
}

/// Dialog do masowej aktualizacji statusu głosowania
class BulkVotingStatusDialog extends StatefulWidget {
  final List<Client> clients;
  final Function(Map<String, VotingStatus>, String?) onUpdateComplete;

  const BulkVotingStatusDialog({
    super.key,
    required this.clients,
    required this.onUpdateComplete,
  });

  @override
  State<BulkVotingStatusDialog> createState() => _BulkVotingStatusDialogState();
}

class _BulkVotingStatusDialogState extends State<BulkVotingStatusDialog> {
  VotingStatus _selectedStatus = VotingStatus.undecided;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Masowa aktualizacja statusu głosowania',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Zaktualizuj status głosowania dla ${widget.clients.length} wybranych klientów:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OptimizedVotingStatusSelector(
              currentStatus: _selectedStatus,
              onStatusChanged: (status) {
                setState(() {
                  _selectedStatus = status;
                });
              },
              isCompact: false,
              showLabels: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Powód zmiany (opcjonalnie)',
                hintText: 'Np. "Decyzja z zebrania zarządu"',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _performBulkUpdate,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Aktualizuj'),
        ),
      ],
    );
  }

  Future<void> _performBulkUpdate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updates = <String, VotingStatus>{};
      for (final client in widget.clients) {
        updates[client.id] = _selectedStatus;
      }

      await widget.onUpdateComplete(
        updates,
        _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas aktualizacji: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
