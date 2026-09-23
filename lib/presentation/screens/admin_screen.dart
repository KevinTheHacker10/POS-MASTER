import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/core/responsive/responsive_helper.dart';
import 'package:pos_master/domain/entities/order_entity.dart';
import 'package:pos_master/domain/entities/user_entity.dart';
import 'package:pos_master/presentation/providers/auth_provider.dart';
import 'package:pos_master/presentation/providers/order_provider.dart';
import 'package:pos_master/theme.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser?.role != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/pos');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: AppColors.softGreen,
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Configurar empresa',
            onPressed: () => context.push('/admin/settings'),
            icon: const Icon(Icons.settings),
          ),
          if (Responsive.isMobile(context))
            IconButton(
              tooltip: 'Productos',
              onPressed: () => context.push('/admin/products'),
              icon: const Icon(Icons.inventory_2),
            )
          else
            TextButton.icon(
              onPressed: () => context.push('/admin/products'),
              icon: const Icon(Icons.inventory_2, color: Colors.white),
              label: const Text('Productos',
                  style: TextStyle(color: Colors.white)),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Reportes'),
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ReportsTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 1 — REPORTES
// =============================================================================

class _ReportsTab extends ConsumerStatefulWidget {
  const _ReportsTab();

  @override
  ConsumerState<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<_ReportsTab> {
  _DateRange _selectedRange = _DateRange.today;

  DateTimeRange _getRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedRange) {
      case _DateRange.today:
        return DateTimeRange(start: today, end: now);
      case _DateRange.week:
        return DateTimeRange(
            start: today.subtract(const Duration(days: 7)), end: now);
      case _DateRange.month:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case _DateRange.all:
        return DateTimeRange(
          start: DateTime(2000),
          end: now.add(const Duration(days: 1)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);
    final range = _getRange();
    final formatter =
        NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);
    final isMobile = Responsive.isMobile(context);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allOrders) {
        // Filtrar por rango y solo completadas
        final orders = allOrders.where((o) {
          return o.status == OrderStatus.completed &&
              o.createdAt.isAfter(range.start) &&
              o.createdAt.isBefore(range.end);
        }).toList();

        final totalVentas = orders.fold<double>(0, (s, o) => s + o.total);
        final totalOrdenes = orders.length;
        final ticketPromedio =
            totalOrdenes > 0 ? totalVentas / totalOrdenes : 0.0;
        final totalImpuestos = orders.fold<double>(0, (s, o) => s + o.tax);

        // Top productos
        final Map<String, _ProductStat> productStats = {};
        for (final o in orders) {
          for (final item in o.items) {
            productStats.update(
              item.productName,
              (s) => _ProductStat(
                name: s.name,
                qty: s.qty + item.quantity,
                revenue: s.revenue + item.total,
              ),
              ifAbsent: () => _ProductStat(
                name: item.productName,
                qty: item.quantity,
                revenue: item.total,
              ),
            );
          }
        }
        final topProducts = productStats.values.toList()
          ..sort((a, b) => b.qty.compareTo(a.qty));

        // Ventas por categoría (usando el nombre para inferir)
        final Map<String, double> byCategory = {};
        for (final o in orders) {
          for (final item in o.items) {
            byCategory.update(
              item.productName.split(' ').first,
              (v) => v + item.total,
              ifAbsent: () => item.total,
            );
          }
        }

        // Ventas por método de pago
        double cashTotal = 0, cardTotal = 0;
        int cashCount = 0, cardCount = 0;
        for (final o in orders) {
          if (o.paymentMethod == PaymentMethod.cash) {
            cashTotal += o.total;
            cashCount++;
          } else {
            cardTotal += o.total;
            cardCount++;
          }
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Selector de rango ──────────────────────────────────────
              _RangeSelector(
                selected: _selectedRange,
                onChanged: (r) => setState(() => _selectedRange = r),
              ),
              const SizedBox(height: 16),

              // ── KPI Cards ──────────────────────────────────────────────
              isMobile
                  ? Column(
                      children: [
                        _KpiCard(
                            'Ventas Totales',
                            formatter.format(totalVentas),
                            Icons.attach_money,
                            AppColors.oliveGreen),
                        const SizedBox(height: 10),
                        _KpiCard('Órdenes', '$totalOrdenes', Icons.receipt_long,
                            AppColors.peach),
                        const SizedBox(height: 10),
                        _KpiCard(
                            'Ticket Promedio',
                            formatter.format(ticketPromedio),
                            Icons.trending_up,
                            AppColors.amber),
                        const SizedBox(height: 10),
                        _KpiCard(
                            'Impuestos (13%)',
                            formatter.format(totalImpuestos),
                            Icons.account_balance,
                            AppColors.coral),
                      ],
                    )
                  : GridView.count(
                      crossAxisCount: isMobile ? 2 : 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _KpiCard(
                            'Ventas Totales',
                            formatter.format(totalVentas),
                            Icons.attach_money,
                            AppColors.oliveGreen),
                        _KpiCard('Órdenes', '$totalOrdenes', Icons.receipt_long,
                            AppColors.peach),
                        _KpiCard(
                            'Ticket Promedio',
                            formatter.format(ticketPromedio),
                            Icons.trending_up,
                            AppColors.amber),
                        _KpiCard(
                            'Impuestos (13%)',
                            formatter.format(totalImpuestos),
                            Icons.account_balance,
                            AppColors.coral),
                      ],
                    ),

              const SizedBox(height: 20),

              // ── Métodos de pago ────────────────────────────────────────
              _SectionCard(
                title: 'Métodos de Pago',
                icon: Icons.payment,
                child: orders.isEmpty
                    ? _emptyState()
                    : isMobile
                        ? Column(
                            children: [
                              _PaymentMethodBar(
                                label: 'Efectivo',
                                icon: Icons.money,
                                count: cashCount,
                                amount: cashTotal,
                                total: totalVentas,
                                color: AppColors.oliveGreen,
                                formatter: formatter,
                              ),
                              const SizedBox(height: 16),
                              _PaymentMethodBar(
                                label: 'Tarjeta',
                                icon: Icons.credit_card,
                                count: cardCount,
                                amount: cardTotal,
                                total: totalVentas,
                                color: AppColors.amber,
                                formatter: formatter,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _PaymentMethodBar(
                                  label: 'Efectivo',
                                  icon: Icons.money,
                                  count: cashCount,
                                  amount: cashTotal,
                                  total: totalVentas,
                                  color: AppColors.oliveGreen,
                                  formatter: formatter,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PaymentMethodBar(
                                  label: 'Tarjeta',
                                  icon: Icons.credit_card,
                                  count: cardCount,
                                  amount: cardTotal,
                                  total: totalVentas,
                                  color: AppColors.amber,
                                  formatter: formatter,
                                ),
                              ),
                            ],
                          ),
              ),

              const SizedBox(height: 16),

              // ── Top productos ──────────────────────────────────────────
              _SectionCard(
                title: 'Productos Más Vendidos',
                icon: Icons.star,
                child: orders.isEmpty
                    ? _emptyState()
                    : Column(
                        children: [
                          for (int i = 0; i < topProducts.take(8).length; i++)
                            _TopProductRow(
                              rank: i + 1,
                              stat: topProducts[i],
                              maxQty: topProducts.first.qty,
                              formatter: formatter,
                            ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              // ── Últimas órdenes ────────────────────────────────────────
              _SectionCard(
                title: 'Últimas Órdenes',
                icon: Icons.history,
                child: orders.isEmpty
                    ? _emptyState()
                    : Column(
                        children: orders.take(10).map((o) {
                          return _OrderRow(order: o, formatter: formatter);
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No hay datos para este período',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      );
}

// =============================================================================
// TAB 2 — USUARIOS
// =============================================================================

class _UsersTab extends ConsumerStatefulWidget {
  const _UsersTab();

  @override
  ConsumerState<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends ConsumerState<_UsersTab> {
  List<UserEntity> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final repo = ref.read(authRepositoryProvider);
    final users = await repo.getAllUsers();
    if (mounted)
      setState(() {
        _users = users;
        _loading = false;
      });
  }

  void _openUserEditor({UserEntity? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _UserEditorSheet(
          initial: user,
          onSaved: _loadUsers,
        ),
      ),
    );
  }

  Future<void> _deleteUser(UserEntity user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Confirma eliminar a "${user.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteUser(user.id);
      await _loadUsers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          if (isMobile)
            Column(
              children: [
                _KpiCard(
                  'Total Usuarios',
                  '${_users.length}',
                  Icons.people,
                  AppColors.oliveGreen,
                ),
                const SizedBox(height: 8),
                _KpiCard(
                  'Administradores',
                  '${_users.where((u) => u.role == UserRole.admin).length}',
                  Icons.admin_panel_settings,
                  AppColors.amber,
                ),
                const SizedBox(height: 8),
                _KpiCard(
                  'Meseros',
                  '${_users.where((u) => u.role == UserRole.waiter).length}',
                  Icons.room_service,
                  AppColors.peach,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    'Total Usuarios',
                    '${_users.length}',
                    Icons.people,
                    AppColors.oliveGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    'Administradores',
                    '${_users.where((u) => u.role == UserRole.admin).length}',
                    Icons.admin_panel_settings,
                    AppColors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    'Meseros',
                    '${_users.where((u) => u.role == UserRole.waiter).length}',
                    Icons.room_service,
                    AppColors.peach,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),

          // Lista de usuarios
          Expanded(
            child: _users.isEmpty
                ? Center(
                    child: Text(
                      'No hay usuarios registrados',
                      style: context.textStyles.bodyLarge
                          ?.withColor(AppColors.oliveGreen),
                    ),
                  )
                : ListView.separated(
                    itemCount: _users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final u = _users[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: u.role == UserRole.admin
                                ? AppColors.oliveGreen.withValues(alpha: 0.15)
                                : AppColors.peach.withValues(alpha: 0.3),
                            child: Text(
                              u.fullName.isNotEmpty
                                  ? u.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: u.role == UserRole.admin
                                    ? AppColors.oliveGreen
                                    : AppColors.peach,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(u.fullName,
                              style: context.textStyles.titleSmall?.semiBold),
                          subtitle: Text('@${u.username}',
                              style: context.textStyles.bodySmall
                                  ?.withColor(Colors.grey[600]!)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: u.role == UserRole.admin
                                      ? AppColors.oliveGreen
                                          .withValues(alpha: 0.1)
                                      : AppColors.peach.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  u.role.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: u.role == UserRole.admin
                                        ? AppColors.oliveGreen
                                        : AppColors.peach,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: AppColors.oliveGreen, size: 20),
                                onPressed: () => _openUserEditor(user: u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.coral, size: 20),
                                onPressed: () => _deleteUser(u),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// USER EDITOR SHEET
// =============================================================================

class _UserEditorSheet extends ConsumerStatefulWidget {
  final UserEntity? initial;
  final VoidCallback onSaved;

  const _UserEditorSheet({this.initial, required this.onSaved});

  @override
  ConsumerState<_UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends ConsumerState<_UserEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  late UserRole _role;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.fullName ?? '');
    _userCtrl = TextEditingController(text: widget.initial?.username ?? '');
    _passCtrl = TextEditingController();
    _role = widget.initial?.role ?? UserRole.waiter;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(authRepositoryProvider);
    final isEdit = widget.initial != null;

    if (isEdit) {
      await repo.updateUser(
        widget.initial!.copyWith(
          fullName: _nameCtrl.text.trim(),
          username: _userCtrl.text.trim(),
          role: _role,
          updatedAt: DateTime.now(),
        ),
        newPassword: _passCtrl.text.isNotEmpty ? _passCtrl.text : null,
      );
    } else {
      await repo.createUser(
        fullName: _nameCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
        role: _role,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Editar usuario' : 'Nuevo usuario',
              style: context.textStyles.titleLarge?.bold,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa el usuario' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText:
                    isEdit ? 'Nueva contraseña (opcional)' : 'Contraseña',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon:
                      Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (!isEdit && (v == null || v.isEmpty)) {
                  return 'Ingresa una contraseña';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<UserRole>(
              value: _role,
              decoration: const InputDecoration(
                labelText: 'Rol',
                prefixIcon: Icon(Icons.badge),
              ),
              items: UserRole.values
                  .map((r) =>
                      DropdownMenuItem(value: r, child: Text(r.displayName)))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? UserRole.waiter),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(isEdit ? Icons.save : Icons.add),
                    label: Text(isEdit ? 'Guardar' : 'Crear'),
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HELPERS DE UI
// =============================================================================

enum _DateRange { today, week, month, all }

class _RangeSelector extends StatelessWidget {
  final _DateRange selected;
  final ValueChanged<_DateRange> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const labels = {
      _DateRange.today: 'Hoy',
      _DateRange.week: '7 días',
      _DateRange.month: 'Este mes',
      _DateRange.all: 'Todo',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _DateRange.values.map((r) {
          final sel = r == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[r]!),
              selected: sel,
              selectedColor: AppColors.oliveGreen,
              labelStyle: TextStyle(
                color: sel ? Colors.white : AppColors.oliveGreen,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => onChanged(r),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style:
                  context.textStyles.labelSmall?.withColor(Colors.grey[600]!),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.oliveGreen, size: 20),
                const SizedBox(width: 8),
                Text(title, style: context.textStyles.titleMedium?.semiBold),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final double amount;
  final double total;
  final Color color;
  final NumberFormat formatter;

  const _PaymentMethodBar({
    required this.label,
    required this.icon,
    required this.count,
    required this.amount,
    required this.total,
    required this.color,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? amount / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(label, style: context.textStyles.titleSmall?.semiBold),
            const Spacer(),
            Text('$count órdenes',
                style: context.textStyles.labelSmall
                    ?.withColor(Colors.grey[600]!)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatter.format(amount)} (${(pct * 100).toStringAsFixed(0)}%)',
          style: context.textStyles.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TopProductRow extends StatelessWidget {
  final int rank;
  final _ProductStat stat;
  final int maxQty;
  final NumberFormat formatter;

  const _TopProductRow({
    required this.rank,
    required this.stat,
    required this.maxQty,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxQty > 0 ? stat.qty / maxQty : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '#$rank',
              style: context.textStyles.labelSmall?.copyWith(
                color: rank == 1 ? AppColors.amber : Colors.grey[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        stat.name,
                        style: context.textStyles.bodyMedium?.semiBold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${stat.qty} uds · ${formatter.format(stat.revenue)}',
                      style: context.textStyles.labelSmall
                          ?.withColor(Colors.grey[600]!),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.oliveGreen.withValues(alpha: 0.1),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.oliveGreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderEntity order;
  final NumberFormat formatter;

  const _OrderRow({required this.order, required this.formatter});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('dd/MM · HH:mm').format(order.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.oliveGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              order.paymentMethod == PaymentMethod.cash
                  ? Icons.money
                  : Icons.credit_card,
              size: 18,
              color: AppColors.oliveGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.userName,
                    style: context.textStyles.bodyMedium?.semiBold),
                Text(
                  '${order.items.length} ítems · $timeStr',
                  style: context.textStyles.labelSmall
                      ?.withColor(Colors.grey[500]!),
                ),
              ],
            ),
          ),
          Text(
            formatter.format(order.total),
            style: context.textStyles.titleSmall?.bold
                .withColor(AppColors.oliveGreen),
          ),
        ],
      ),
    );
  }
}

class _ProductStat {
  final String name;
  final int qty;
  final double revenue;
  const _ProductStat(
      {required this.name, required this.qty, required this.revenue});
}
