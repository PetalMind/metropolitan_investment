import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models_and_services.dart';
import '../theme/app_theme_professional.dart';

class EmployeeCardsWidget extends StatefulWidget {
  final List<Employee> employees;
  final Function(Employee) onEdit;
  final Function(Employee) onDelete;
  final Function(Employee)? onTap;
  final bool canEdit;
  final ScrollController? scrollController;

  const EmployeeCardsWidget({
    super.key,
    required this.employees,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    required this.canEdit,
    this.scrollController,
  });

  @override
  State<EmployeeCardsWidget> createState() => _EmployeeCardsWidgetState();
}

class _EmployeeCardsWidgetState extends State<EmployeeCardsWidget>
    with TickerProviderStateMixin {
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.employees.isEmpty) {
      return const Center(child: EmptyEmployeesWidget());
    }

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return GridView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _getCrossAxisCount(context),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: _getAspectRatio(context),
          ),
          itemCount: widget.employees.length,
          itemBuilder: (context, index) {
            final employee = widget.employees[index];

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300 + (index * 50)),
              tween: Tween(begin: 0.0, end: _staggerController.value),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: EmployeeCard(
                      employee: employee,
                      canEdit: widget.canEdit,
                      onEdit: () => widget.onEdit(employee),
                      onDelete: () => widget.onDelete(employee),
                      onTap: widget.onTap != null
                          ? () => widget.onTap!(employee)
                          : null,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 800) return 1.2;
    if (width > 600) return 1.1;
    return 1.0;
  }
}

class EmployeeCard extends StatefulWidget {
  final Employee employee;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const EmployeeCard({
    super.key,
    required this.employee,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  State<EmployeeCard> createState() => _EmployeeCardState();
}

class _EmployeeCardState extends State<EmployeeCard>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pressController;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 2, end: 8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.01)).animate(
          CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    if (!mounted) return;
    setState(() {
      _isHovered = isHovered;
    });

    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (!mounted) return;
    setState(() {
      _isPressed = true;
    });
    _pressController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  void _onTapCancel() {
    if (!mounted) return;
    setState(() {
      _isPressed = false;
    });
    _pressController.reverse();
  }

  Color _getStatusColor() {
    return widget.employee.isActive
        ? AppTheme.successPrimary
        : AppTheme.errorPrimary;
  }

  String _getStatusText() {
    return widget.employee.isActive ? 'Aktywny' : 'Nieaktywny';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverController, _pressController]),
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: MouseRegion(
              onEnter: (_) => _onHover(true),
              onExit: (_) => _onHover(false),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPrimary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: _elevationAnimation.value,
                        offset: Offset(0, _elevationAnimation.value / 2),
                      ),
                    ],
                    border: Border.all(
                      color: _isHovered
                          ? AppTheme.primaryColor.withValues(alpha: 0.3)
                          : AppTheme.borderPrimary.withValues(alpha: 0.2),
                      width: _isHovered ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with avatar and status
                            Row(
                              children: [
                                // Avatar
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 300),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: 0.8 + (0.2 * value),
                                      child: Hero(
                                        tag:
                                            'employee_avatar_${widget.employee.id}',
                                        child: Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppTheme.primaryColor,
                                                AppTheme.primaryColor
                                                    .withValues(alpha: 0.7),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${widget.employee.firstName[0]}${widget.employee.lastName[0]}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const Spacer(),

                                // Status badge
                                TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 400),
                                  tween: Tween(begin: 0.0, end: 1.0),
                                  builder: (context, value, child) {
                                    return Transform.scale(
                                      scale: value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor().withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: _getStatusColor().withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _getStatusText(),
                                              style: TextStyle(
                                                color: _getStatusColor(),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Name
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 500),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: Text(
                                      '${widget.employee.firstName} ${widget.employee.lastName}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 8),

                            // Position
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 600),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(20 * (1 - value), 0),
                                  child: Opacity(
                                    opacity: value,
                                    child: Text(
                                      widget.employee.position,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            // Contact info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Email
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 700),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(20 * (1 - value), 0),
                                        child: Opacity(
                                          opacity: value,
                                          child: _ContactInfoRow(
                                            icon: Icons.email_outlined,
                                            text: widget.employee.email,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  const SizedBox(height: 8),

                                  // Phone
                                  if (widget.employee.phone.isNotEmpty)
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 800,
                                      ),
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      builder: (context, value, child) {
                                        return Transform.translate(
                                          offset: Offset(20 * (1 - value), 0),
                                          child: Opacity(
                                            opacity: value,
                                            child: _ContactInfoRow(
                                              icon: Icons.phone_outlined,
                                              text: widget.employee.phone,
                                              color: AppTheme.successPrimary,
                                            ),
                                          ),
                                        );
                                      },
                                    ),

                                  const SizedBox(height: 8),

                                  // Branch
                                  TweenAnimationBuilder<double>(
                                    duration: const Duration(milliseconds: 900),
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    builder: (context, value, child) {
                                      return Transform.translate(
                                        offset: Offset(20 * (1 - value), 0),
                                        child: Opacity(
                                          opacity: value,
                                          child: _ContactInfoRow(
                                            icon: Icons.business_outlined,
                                            text:
                                                '${widget.employee.branchCode} - ${widget.employee.branchName}',
                                            color: AppTheme.secondaryGold,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions overlay
                      if (_isHovered || _isPressed)
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 200),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(
                                    alpha: 0.7 * value,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Opacity(
                                  opacity: value,
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Edit button
                                        _ActionButton(
                                          icon: Icons.edit_outlined,
                                          label: 'Edytuj',
                                          color: widget.canEdit
                                              ? AppTheme.secondaryGold
                                              : Colors.grey,
                                          onPressed: widget.canEdit
                                              ? widget.onEdit
                                              : null,
                                        ),

                                        const SizedBox(width: 16),

                                        // Delete button
                                        _ActionButton(
                                          icon: Icons.delete_outline,
                                          label: 'Usuń',
                                          color: widget.canEdit
                                              ? AppTheme.errorPrimary
                                              : Colors.grey,
                                          onPressed: widget.canEdit
                                              ? widget.onDelete
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ContactInfoRow({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(_scaleController);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _scaleController.forward(),
            onTapUp: (_) => _scaleController.reverse(),
            onTapCancel: () => _scaleController.reverse(),
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onPressed?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyEmployeesWidget extends StatelessWidget {
  const EmptyEmployeesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.textTertiary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    Icons.people_outline,
                    size: 64,
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Brak pracowników',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dodaj pierwszego pracownika lub zmień kryteria wyszukiwania',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
