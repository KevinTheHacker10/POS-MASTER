import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_master/core/constants.dart';
import 'package:pos_master/core/responsive/responsive_helper.dart';
import 'package:pos_master/domain/entities/product_entity.dart';
import 'package:pos_master/presentation/providers/auth_provider.dart';
import 'package:pos_master/presentation/providers/product_provider.dart';
import 'package:pos_master/presentation/widgets/product_card.dart';
import 'package:pos_master/theme.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  ProductCategory? _categoryFilter;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openEditor({ProductEntity? product}) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _ProductEditorSheet(initial: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final productsAsync = ref.watch(productProvider);

    if (currentUser?.role != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/pos');
      });
      return const SizedBox.shrink();
    }

    final query = _searchCtrl.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.softGreen,
      appBar: AppBar(
        title: const Text('Productos • Administración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Nuevo producto',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Filtros ────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final search = TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre o descripción…',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                tooltip: 'Limpiar',
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
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
                                  .withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    );
                    final category = DropdownButtonFormField<ProductCategory?>(
                      value: _categoryFilter,
                      items: [
                        const DropdownMenuItem<ProductCategory?>(
                          value: null,
                          child: Text('Todas'),
                        ),
                        ...ProductCategory.values
                            .map((c) => DropdownMenuItem<ProductCategory?>(
                                  value: c,
                                  child: Text('${c.icon} ${c.displayName}'),
                                )),
                      ],
                      onChanged: (v) => setState(() => _categoryFilter = v),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.category),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16)),
                        labelText: 'Categoría',
                      ),
                    );
                    if (compact) {
                      return Column(
                        children: [
                          search,
                          const SizedBox(height: 12),
                          category,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 3, child: search),
                        const SizedBox(width: 12),
                        Expanded(child: category),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Lista de productos ─────────────────────────────────────
            Expanded(
              child: productsAsync.when(
                data: (list) {
                  var items = list;
                  if (_categoryFilter != null) {
                    items = items
                        .where((e) => e.category == _categoryFilter)
                        .toList();
                  }
                  if (query.isNotEmpty) {
                    items = items
                        .where((e) =>
                            e.name.toLowerCase().contains(query) ||
                            (e.description ?? '').toLowerCase().contains(query))
                        .toList();
                  }

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Sin productos para mostrar',
                        style: context.textStyles.bodyLarge
                            ?.withColor(AppColors.oliveGreen),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final p = items[index];
                      if (Responsive.isMobile(context)) {
                        return _MobileProductTile(
                          product: p,
                          onEdit: () => _openEditor(product: p),
                          onAvailabilityChanged: (value) async {
                            await ref
                                .read(productProvider.notifier)
                                .updateProduct(
                                  p.copyWith(
                                    isAvailable: value,
                                    updatedAt: DateTime.now(),
                                  ),
                                );
                          },
                        );
                      }
                      return Card(
                        child: Padding(
                          padding: AppSpacing.paddingMd,
                          child: Row(
                            children: [
                              // ── Miniatura imagen ──────────────────
                              SizedBox(
                                width: 56,
                                height: 56,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: ProductImage(
                                    product: p,
                                    bgColor: _bgColorFor(p.category),
                                    emojiSize: 26,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // ── Info ──────────────────────────────
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: context.textStyles
                                                .titleMedium?.semiBold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            p.category.displayName,
                                            style: context.textStyles.labelSmall
                                                ?.withColor(Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      p.description ?? '—',
                                      style: context.textStyles.bodySmall
                                          ?.withColor(Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                    ),
                                    // Muestra URL si tiene imagen
                                    if (p.hasCustomImage)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Row(
                                          children: [
                                            Icon(Icons.image,
                                                size: 12,
                                                color: AppColors.oliveGreen),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                p.imageUrl!,
                                                style: context
                                                    .textStyles.labelSmall
                                                    ?.withColor(
                                                        AppColors.oliveGreen),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // ── Precio + toggle + acciones ────────
                              Text(
                                '${AppConstants.currency}${p.price.toStringAsFixed(0)}',
                                style: context.textStyles.titleMedium?.bold,
                              ),
                              const SizedBox(width: 12),
                              Row(
                                children: [
                                  Icon(Icons.circle,
                                      size: 10,
                                      color: p.isAvailable
                                          ? Colors.green
                                          : Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Switch(
                                    value: p.isAvailable,
                                    onChanged: (v) async {
                                      final updated = p.copyWith(
                                        isAvailable: v,
                                        updatedAt: DateTime.now(),
                                      );
                                      await ref
                                          .read(productProvider.notifier)
                                          .updateProduct(updated);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Editar',
                                icon: const Icon(Icons.edit,
                                    color: AppColors.oliveGreen),
                                onPressed: () => _openEditor(product: p),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                icon: const Icon(Icons.delete,
                                    color: AppColors.coral),
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Eliminar producto'),
                                      content: Text(
                                          '¿Confirma eliminar "${p.name}"?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.delete),
                                          label: const Text('Eliminar'),
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await ref
                                        .read(productProvider.notifier)
                                        .deleteProduct(p.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nuevo producto'),
      ),
    );
  }

  Color _bgColorFor(ProductCategory cat) {
    switch (cat) {
      case ProductCategory.meals:
        return const Color(0xFFDFF2D0);
      case ProductCategory.drinks:
        return const Color(0xFFFFE4F0);
      case ProductCategory.groceries:
        return const Color(0xFFFFF3CC);
      case ProductCategory.desserts:
        return const Color(0xFFE8DDD0);
      case ProductCategory.services:
        return const Color(0xFFDDEBFF);
      case ProductCategory.other:
        return const Color(0xFFE8E8E8);
    }
  }
}

// =============================================================================
// EDITOR DE PRODUCTO — incluye campo de imagen
// =============================================================================

class _MobileProductTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onEdit;
  final ValueChanged<bool> onAvailabilityChanged;

  const _MobileProductTile({
    required this.product,
    required this.onEdit,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 52,
                  height: 52,
                  child: ProductImage(
                    product: product,
                    bgColor: Theme.of(context).colorScheme.primaryContainer,
                    emojiSize: 24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall?.semiBold,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${product.category.displayName} · ${AppConstants.currency}${product.price.toStringAsFixed(0)}',
                        style: context.textStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Editar',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: AppColors.oliveGreen),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: product.isAvailable ? Colors.green : Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      product.isAvailable ? 'Disponible' : 'No disponible'),
                ),
                Switch(
                  value: product.isAvailable,
                  onChanged: onAvailabilityChanged,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductEditorSheet extends ConsumerStatefulWidget {
  final ProductEntity? initial;
  const _ProductEditorSheet({this.initial});

  @override
  ConsumerState<_ProductEditorSheet> createState() =>
      _ProductEditorSheetState();
}

class _ProductEditorSheetState extends ConsumerState<_ProductEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageCtrl;
  late ProductCategory _category;
  late bool _available;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _priceCtrl = TextEditingController(
        text: widget.initial?.price.toStringAsFixed(0) ?? '');
    _descCtrl = TextEditingController(text: widget.initial?.description ?? '');
    _imageCtrl = TextEditingController(text: widget.initial?.imageUrl ?? '');
    _category = widget.initial?.category ?? ProductCategory.meals;
    _available = widget.initial?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  // Preview en tiempo real de la imagen
  ProductEntity get _previewProduct => ProductEntity(
        id: 'preview',
        name: _nameCtrl.text.isEmpty ? 'Vista previa' : _nameCtrl.text,
        price: 0,
        category: _category,
        description: null,
        imageUrl:
            _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  Color get _bgColor {
    switch (_category) {
      case ProductCategory.meals:
        return const Color(0xFFDFF2D0);
      case ProductCategory.drinks:
        return const Color(0xFFFFE4F0);
      case ProductCategory.groceries:
        return const Color(0xFFFFF3CC);
      case ProductCategory.desserts:
        return const Color(0xFFE8DDD0);
      case ProductCategory.services:
        return const Color(0xFFDDEBFF);
      case ProductCategory.other:
        return const Color(0xFFE8E8E8);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(productProvider.notifier);
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;
    final imageUrl =
        _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim();

    if (widget.initial == null) {
      await notifier.createProduct(
        name: _nameCtrl.text.trim(),
        price: price,
        category: _category,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        imageUrl: imageUrl,
      );
    } else {
      final updated = widget.initial!.copyWith(
        name: _nameCtrl.text.trim(),
        price: price,
        category: _category,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        isAvailable: _available,
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );
      await notifier.updateProduct(updated);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit ? 'Editar producto' : 'Nuevo producto',
              style: context.textStyles.titleLarge?.bold,
            ),
            const SizedBox(height: 16),

            // ── Preview de imagen ────────────────────────────────────
            Center(
              child: StatefulBuilder(
                builder: (_, setLocal) {
                  return Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ProductImage(
                          product: _previewProduct,
                          bgColor: _bgColor,
                          emojiSize: 48,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Vista previa',
                        style: context.textStyles.labelSmall
                            ?.withColor(Colors.grey[500]!),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Campo imagen ─────────────────────────────────────────
            TextFormField(
              controller: _imageCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Imagen (URL o emoji)',
                hintText: 'https://... o 🍵',
                prefixIcon: const Icon(Icons.image),
                suffixIcon: _imageCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _imageCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                helperText:
                    'Pegá una URL de imagen o escribí un emoji personalizado',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                      color: AppColors.oliveGreen.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: AppColors.oliveGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Nombre ───────────────────────────────────────────────
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.emoji_food_beverage),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingrese un nombre' : null,
            ),
            const SizedBox(height: 12),

            // ── Precio ───────────────────────────────────────────────
            TextFormField(
              controller: _priceCtrl,
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final value = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (value == null || value <= 0) {
                  return 'Ingrese un precio válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // ── Categoría ────────────────────────────────────────────
            DropdownButtonFormField<ProductCategory>(
              value: _category,
              items: ProductCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.icon} ${c.displayName}'),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? ProductCategory.meals),
              decoration: const InputDecoration(
                labelText: 'Categoría',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 12),

            // ── Descripción ──────────────────────────────────────────
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                prefixIcon: Icon(Icons.description),
              ),
            ),

            // ── Disponible (solo en edición) ─────────────────────────
            if (isEdit) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Disponible para la venta',
                      style: context.textStyles.titleSmall,
                    ),
                  ),
                  Switch(
                    value: _available,
                    onChanged: (v) => setState(() => _available = v),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // ── Botones ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(isEdit ? Icons.save : Icons.add),
                    label: Text(isEdit ? 'Guardar' : 'Crear producto'),
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
