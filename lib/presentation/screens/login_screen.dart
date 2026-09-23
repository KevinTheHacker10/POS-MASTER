import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:matcha_lovers_506/core/constants.dart';
import 'package:matcha_lovers_506/core/responsive/responsive_helper.dart';
import 'package:matcha_lovers_506/presentation/providers/auth_provider.dart';
import 'package:matcha_lovers_506/presentation/providers/business_settings_provider.dart';
import 'package:matcha_lovers_506/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor ingresa usuario y contraseña');
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(authProvider.notifier).login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      context.go('/pos');
    } else {
      _showError('Usuario o contraseña incorrectos');
    }
  }

  void _startSelfService() {
    ref.read(authProvider.notifier).startSelfService();
    context.go('/pos');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(businessSettingsProvider);
    return Scaffold(
      backgroundColor: AppColors.softGreen,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _MobileLogin(
            form: _buildForm(context),
            businessName: settings.businessName,
          ),
          desktop: _DesktopLogin(
            form: _buildForm(context),
            businessName: settings.businessName,
            businessType: settings.businessType.label,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared form card (same content, just changes max-width per layout)
  // ---------------------------------------------------------------------------

  Widget _buildForm(BuildContext context) {
    final maxWidth = Responsive.value<double>(
      context,
      mobile: double.infinity,
      tablet: 420,
      desktop: 420,
    );

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Responsive.isDesktop(context)
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      padding: AppSpacing.paddingXl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Iniciar Sesión',
            style: context.textStyles.titleLarge?.bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Usuario',
              prefixIcon: const Icon(Icons.person_outline, color: AppColors.oliveGreen),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.oliveGreen.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.oliveGreen, width: 2),
              ),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.oliveGreen),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.oliveGreen,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.oliveGreen.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.oliveGreen, width: 2),
              ),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Ingresar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _isLoading ? null : _startSelfService,
            icon: const Icon(Icons.touch_app),
            label: const Text('Entrar como cliente · Autoservicio'),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildCredentialsHint(context),
        ],
      ),
    );
  }

  Widget _buildCredentialsHint(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.softGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('Usuarios de prueba:', style: context.textStyles.labelSmall?.bold),
          const SizedBox(height: AppSpacing.sm),
          Text('Admin: admin / admin123', style: context.textStyles.bodySmall),
          Text('Mesero: mesero / mesero123', style: context.textStyles.bodySmall),
        ],
      ),
    );
  }
}

// =============================================================================
// MOBILE LAYOUT — stacked, centered
// =============================================================================

class _MobileLogin extends StatelessWidget {
  final Widget form;
  final String businessName;
  const _MobileLogin({required this.form, required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Logo(size: 100),
            const SizedBox(height: AppSpacing.xl),
            _AppTitle(businessName: businessName),
            const SizedBox(height: AppSpacing.xxl),
            form,
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DESKTOP / TABLET LAYOUT — two columns side by side
// =============================================================================

class _DesktopLogin extends StatelessWidget {
  final Widget form;
  final String businessName;
  final String businessType;
  const _DesktopLogin({
    required this.form,
    required this.businessName,
    required this.businessType,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          child: Container(
            color: AppColors.oliveGreen,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Logo(size: 140, bgColor: Colors.white.withValues(alpha: 0.15)),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  businessName,
                  style: context.textStyles.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '$businessType · ${AppConstants.appName}',
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                // Feature highlights
                ...[
                  (Icons.speed, 'Rápido y eficiente'),
                  (Icons.devices, 'Disponible en todos tus dispositivos'),
                  (Icons.bar_chart, 'Reportes en tiempo real'),
                ].map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 48),
                    child: Row(
                      children: [
                        Icon(e.$1, color: Colors.white.withValues(alpha: 0.9), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          e.$2,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right: form
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _AppTitle(
                    color: AppColors.oliveGreen,
                    businessName: businessName,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  form,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SHARED SUB-WIDGETS
// =============================================================================

class _Logo extends StatelessWidget {
  final double size;
  final Color? bgColor;

  const _Logo({required this.size, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? Colors.white,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(
        child: Text('🍵', style: TextStyle(fontSize: size * 0.53)),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  final Color? color;
  final String businessName;
  const _AppTitle({this.color, required this.businessName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          businessName,
          style: context.textStyles.headlineMedium?.copyWith(
            color: color ?? AppColors.oliveGreen,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppConstants.appName,
          style: context.textStyles.bodyLarge?.copyWith(
            color: (color ?? AppColors.oliveGreen).withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
