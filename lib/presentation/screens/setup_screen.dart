import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/domain/entities/business_settings.dart';
import 'package:matcha_lovers_506/presentation/providers/business_settings_provider.dart';

class SetupScreen extends ConsumerStatefulWidget {
  final String destinationAfterSave;

  const SetupScreen({
    super.key,
    this.destinationAfterSave = '/login',
  });

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late BusinessType _type;
  late AppPalette _palette;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(businessSettingsProvider);
    _nameController = TextEditingController(text: settings.businessName);
    _type = settings.businessType;
    _palette = settings.palette;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(businessSettingsProvider.notifier).save(
          businessName: _nameController.text,
          businessType: _type,
          palette: _palette,
        );
    if (mounted) context.go(widget.destinationAfterSave);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(Icons.point_of_sale,
                            size: 64, color: _palette.color),
                        const SizedBox(height: 12),
                        Text(AppConstants.appName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                        const SizedBox(height: 6),
                        Text('Configura tu negocio',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la empresa',
                            prefixIcon: Icon(Icons.storefront),
                          ),
                          validator: (value) => value == null ||
                                  value.trim().isEmpty
                              ? 'Ingresa el nombre que aparecerá en el sistema'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<BusinessType>(
                          value: _type,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de establecimiento',
                            prefixIcon: Icon(Icons.business),
                          ),
                          items: BusinessType.values
                              .map((value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value.label),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _type = value ?? _type),
                        ),
                        const SizedBox(height: 22),
                        Text('Paleta de color',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: AppPalette.values.map((palette) {
                            return ChoiceChip(
                              selected: _palette == palette,
                              avatar:
                                  CircleAvatar(backgroundColor: palette.color),
                              label: Text(palette.label),
                              onSelected: (_) =>
                                  setState(() => _palette = palette),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 28),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.arrow_forward),
                          label: const Text('Guardar y continuar'),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Después podrás crear y editar el menú o catálogo desde Administración.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
