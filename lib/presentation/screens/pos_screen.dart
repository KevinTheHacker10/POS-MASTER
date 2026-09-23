import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/domain/entities/product_entity.dart';
import 'package:matcha_lovers_506/presentation/providers/auth_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/business_settings_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/cart_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/product_provider.dart';
import 'package:matcha_lovers_506/presentation/widgets/cart_panel.dart';
import 'package:matcha_lovers_506/presentation/widgets/product_card.dart';
import 'package:matcha_lovers_506/core/responsive/responsive_helper.dart';
import 'package:matcha_lovers_506/theme.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  ProductCategory _selectedCategory = ProductCategory.meals;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(productFilterProvider.notifier).setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Cart bottom sheet — shown only on mobile
  // ---------------------------------------------------------------------------

  void _openCartSheet() {
    final cart = ref.read(cartProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => CartPanel(
          cartItems: cart,
          onCheckout: () {
            Navigator.of(ctx).pop();
            context.push('/checkout');
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filters bottom sheet
  // ---------------------------------------------------------------------------

  void _openFiltersSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final filters = ref.read(productFilterProvider);
        final productsAsync = ref.read(productProvider);
        final items = productsAsync.maybeWhen(
          data: (list) =>
              list.where((p) => p.category == _selectedCategory).toList(),
          orElse: () => <ProductEntity>[],
        );

        double minPrice = items.isEmpty
            ? 0
            : items.map((e) => e.price).reduce((a, b) => a < b ? a : b);
        double maxPrice = items.isEmpty
            ? 0
            : items.map((e) => e.price).reduce((a, b) => a > b ? a : b);

        double currentMin = filters.minPrice ?? minPrice;
        double currentMax = filters.maxPrice ?? maxPrice;
        ProductSort currentSort = filters.sort;
        bool onlyAvailable = filters.onlyAvailable;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filtros', style: context.textStyles.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.tune,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Rango de precio',
                          style: context.textStyles.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    Text('Sin productos para filtrar',
                        style: context.textStyles.bodyMedium)
                  else ...[
                    RangeSlider(
                      values: RangeValues(currentMin, currentMax),
                      min: minPrice,
                      max: maxPrice,
                      divisions: (maxPrice - minPrice).round() > 0
                          ? (maxPrice - minPrice).round()
                          : null,
                      labels: RangeLabels(
                        '₡${currentMin.toStringAsFixed(0)}',
                        '₡${currentMax.toStringAsFixed(0)}',
                      ),
                      onChanged: (v) => setModalState(() {
                        currentMin = v.start;
                        currentMax = v.end;
                      }),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Mín: ₡${currentMin.toStringAsFixed(0)}'),
                        Text('Máx: ₡${currentMax.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.sort,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Ordenar por',
                          style: context.textStyles.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Relevancia'),
                        selected: currentSort == ProductSort.relevance,
                        onSelected: (_) => setModalState(
                            () => currentSort = ProductSort.relevance),
                      ),
                      ChoiceChip(
                        label: const Text('Precio ↑'),
                        selected: currentSort == ProductSort.priceAsc,
                        onSelected: (_) => setModalState(
                            () => currentSort = ProductSort.priceAsc),
                      ),
                      ChoiceChip(
                        label: const Text('Precio ↓'),
                        selected: currentSort == ProductSort.priceDesc,
                        onSelected: (_) => setModalState(
                            () => currentSort = ProductSort.priceDesc),
                      ),
                      ChoiceChip(
                        label: const Text('Nombre A-Z'),
                        selected: currentSort == ProductSort.nameAsc,
                        onSelected: (_) => setModalState(
                            () => currentSort = ProductSort.nameAsc),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Mostrar solo disponibles',
                            style: context.textStyles.titleMedium),
                      ),
                      Switch(
                        value: onlyAvailable,
                        onChanged: (v) =>
                            setModalState(() => onlyAvailable = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Limpiar'),
                          onPressed: () {
                            ref.read(productFilterProvider.notifier).clear();
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Aplicar filtros'),
                          onPressed: () {
                            ref.read(productFilterProvider.notifier)
                              ..setPriceRange(min: currentMin, max: currentMax)
                              ..setSort(currentSort)
                              ..setOnlyAvailable(onlyAvailable);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final products =
        ref.watch(filteredProductsByCategoryProvider(_selectedCategory));
    final filters = ref.watch(productFilterProvider);
    final cart = ref.watch(cartProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.softGreen,
      appBar: _buildAppBar(context, currentUser),

      // On mobile: FAB opens cart as bottom sheet
      floatingActionButton: isMobile
          ? CartFab(
              itemCount: cart.fold(0, (sum, item) => sum + item.quantity),
              onOpenCart: _openCartSheet,
            )
          : null,

      body: Row(
        children: [
          // ── Left: product catalog ──────────────────────────────────────────
          Expanded(
            child: Column(
              children: [
                _buildCategoryBar(),
                _buildSearchBar(context, filters),
                Expanded(child: _buildProductGrid(context, products, filters)),
              ],
            ),
          ),

          // ── Right: cart panel (tablet + desktop only) ─────────────────────
          if (!isMobile)
            SizedBox(
              width: Responsive.cartPanelWidth(context),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(-2, 0),
                    ),
                  ],
                ),
                child: CartPanel(
                  cartItems: cart,
                  onCheckout: () => context.push('/checkout'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, currentUser) {
    final isDesktop = Responsive.isDesktop(context);
    final businessName = ref.watch(businessSettingsProvider).businessName;

    return AppBar(
      title: Text(businessName.isEmpty ? AppConstants.appName : businessName),
      actions: [
        if (currentUser?.role == UserRole.admin)
          isDesktop
              ? TextButton.icon(
                  icon:
                      const Icon(Icons.bar_chart_rounded, color: Colors.white),
                  label: const Text('Admin',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => context.push('/admin'),
                )
              : IconButton(
                  icon: const Icon(Icons.bar_chart_rounded),
                  onPressed: () => context.push('/admin'),
                  tooltip: 'Panel Admin',
                ),
        if (currentUser?.role != UserRole.customer)
          isDesktop
              ? TextButton.icon(
                  icon: const Icon(Icons.history, color: Colors.white),
                  label: const Text('Historial',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => context.push('/orders'),
                )
              : IconButton(
                  icon: const Icon(Icons.history),
                  onPressed: () => context.push('/orders'),
                  tooltip: 'Historial',
                ),
        if (isDesktop && currentUser != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    currentUser.fullName,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          tooltip: 'Cerrar sesión',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      padding: AppSpacing.paddingMd,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ProductCategory.values.map((category) {
            final isSelected = category == _selectedCategory;
            return Padding(
              padding: AppSpacing.horizontalXs,
              child: CategoryChip(
                label: category.displayName,
                icon: category.icon,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedCategory = category),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, filters) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: Responsive.isMobile(context)
                    ? 'Buscar productos...'
                    : 'Buscar productos, sabores o descripciones...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filters.hasQuery
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(productFilterProvider.notifier).setQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            icon:
                Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
            label: Text(
              'Filtros',
              style: context.textStyles.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _openFiltersSheet,
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context, List products, filters) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          filters.hasAnyFilter
              ? 'Sin resultados. Ajusta la búsqueda o los filtros'
              : 'No hay productos disponibles',
          style: context.textStyles.bodyLarge
              ?.copyWith(color: AppColors.oliveGreen),
          textAlign: TextAlign.center,
        ),
      );
    }

    final columns = Responsive.gridColumns(context);
    final padding = Responsive.horizontalPadding(context);

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: Responsive.value(
          context,
          mobile: 0.75,
          tablet: 0.85,
          desktop: 0.9,
        ),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => ref.read(cartProvider.notifier).addProduct(product),
        );
      },
    );
  }
}

// =============================================================================
// CART FAB (mobile only)
// =============================================================================

class CartFab extends StatelessWidget {
  final int itemCount;
  final VoidCallback onOpenCart;

  const CartFab({super.key, required this.itemCount, required this.onOpenCart});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onOpenCart,
      backgroundColor: AppColors.oliveGreen,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart, color: Colors.white),
          if (itemCount > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.coral,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      label: Text(
        itemCount > 0 ? 'Carrito ($itemCount)' : 'Ver carrito',
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// =============================================================================
// CATEGORY CHIP (unchanged)
// =============================================================================

class CategoryChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.oliveGreen : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.oliveGreen
                  : AppColors.oliveGreen.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.textStyles.titleMedium?.copyWith(
                  color: isSelected ? Colors.white : AppColors.oliveGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
