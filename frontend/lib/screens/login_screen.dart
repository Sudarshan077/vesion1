import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _tenantController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _obscurePassword = true;
  String _selectedRole = 'DISTRIBUTOR';
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();

    if (_isSignUp) {
      final success = await auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        tenantName: _tenantController.text.trim(),
        role: _selectedRole,
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created! Please sign in.')),
        );
        setState(() => _isSignUp = false);
      }
    } else {
      await auth.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryDark,
              Color(0xFF0A1628),
              AppTheme.primaryMid,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isWide) ...[
                    // Left branding panel
                    SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.hub_rounded,
                              color: AppTheme.accent,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Distributor\nManagement\nSystem',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 42,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Streamline your distribution supply chain with\nreal-time inventory, orders, and analytics.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildFeatureChip(Icons.inventory_2_rounded, 'Inventory Management'),
                          const SizedBox(height: 12),
                          _buildFeatureChip(Icons.receipt_long_rounded, 'Order Tracking'),
                          const SizedBox(height: 12),
                          _buildFeatureChip(Icons.analytics_rounded, 'Real-time Analytics'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 80),
                  ],
                  // Login/Signup form
                  Container(
                    width: isWide ? 420 : double.infinity,
                    constraints: BoxConstraints(maxWidth: isWide ? 420 : 460),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isWide) ...[
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.hub_rounded,
                                  color: AppTheme.accent,
                                  size: 32,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            _isSignUp ? 'Create Account' : 'Welcome Back',
                            style: Theme.of(context).textTheme.displayMedium,
                            textAlign: isWide ? TextAlign.left : TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isSignUp
                                ? 'Fill in your details to get started'
                                : 'Sign in to your DMS dashboard',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: isWide ? TextAlign.left : TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          if (auth.error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.error!,
                                      style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_isSignUp) ...[
                            // Role selector
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _buildRoleChip('DISTRIBUTOR', Icons.warehouse_rounded, 'Distributor'),
                                  _buildRoleChip('RETAILER', Icons.store_rounded, 'Retailer'),
                                  _buildRoleChip('CONSUMER', Icons.person_rounded, 'Consumer'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _tenantController,
                              decoration: const InputDecoration(
                                labelText: 'Company / Tenant Name',
                                prefixIcon: Icon(Icons.business_rounded),
                              ),
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (!v.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (v.length < 6) return 'Min 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _submit,
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () => setState(() {
                              _isSignUp = !_isSignUp;
                            }),
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Sign In'
                                  : 'Don\'t have an account? Sign Up',
                              style: const TextStyle(color: AppTheme.accent),
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
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role, IconData icon, String label) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected ? Border.all(color: AppTheme.accent.withValues(alpha: 0.4)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? AppTheme.accent : AppTheme.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                color: isSelected ? AppTheme.accent : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15)),
      ],
    );
  }
}
