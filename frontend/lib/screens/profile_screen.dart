import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _profile = {};
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.getProfile();
      if (result['statusCode'] == 200) {
        setState(() {
          _profile = result['body'];
          _populateFields();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _populateFields() {
    _nameController.text = _profile['fullName'] ?? '';
    _phoneController.text = _profile['phone'] ?? '';
    _addressController.text = _profile['address'] ?? '';
    _cityController.text = _profile['city'] ?? '';
    _stateController.text = _profile['state'] ?? '';
    _pincodeController.text = _profile['pincode'] ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final result = await ApiService.updateProfile({
        'fullName': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
      });
      if (result['statusCode'] == 200) {
        setState(() {
          _profile = result['body'];
          _isEditing = false;
          _isSaving = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      } else {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['body']['message'] ?? 'Update failed')),
          );
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection error')),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPwController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPwController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPwController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_rounded, color: AppTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPwController.text != confirmPwController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              if (newPwController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 6 characters')),
                );
                return;
              }
              try {
                final result = await ApiService.changePassword(
                  currentPwController.text,
                  newPwController.text,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['body']['message'] ?? 'Password changed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Connection error')),
                  );
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  String _getRoleBadge() {
    final roles = _profile['roles'] as List? ?? [];
    if (roles.contains('ROLE_ADMIN')) return 'Distributor';
    if (roles.contains('ROLE_RETAILER')) return 'Retailer';
    if (roles.contains('ROLE_CUSTOMER')) return 'Consumer';
    return 'User';
  }

  Color _getRoleBadgeColor() {
    final roles = _profile['roles'] as List? ?? [];
    if (roles.contains('ROLE_ADMIN')) return AppTheme.accent;
    if (roles.contains('ROLE_RETAILER')) return AppTheme.info;
    if (roles.contains('ROLE_CUSTOMER')) return AppTheme.warning;
    return AppTheme.textSecondary;
  }

  String _getInitials() {
    final name = _profile['fullName'] ?? '';
    final parts = name.toString().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: AppTheme.accent,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header
          Text('My Profile', style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 4),
          Text('Manage your account details', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Profile Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRoleBadgeColor().withValues(alpha: 0.15),
                  AppTheme.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getRoleBadgeColor(), _getRoleBadgeColor().withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(),
                      style: TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _profile['fullName'] ?? 'User',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile['email'] ?? '',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getRoleBadgeColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRoleBadge(),
                          style: TextStyle(
                            color: _getRoleBadgeColor(),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Personal Information Section
          _buildSectionHeader(
            'Personal Information',
            Icons.person_outline_rounded,
            trailing: _isEditing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          _populateFields();
                          setState(() => _isEditing = false);
                        },
                        child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save'),
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.edit_rounded, color: AppTheme.accent, size: 20),
                    onPressed: () => setState(() => _isEditing = true),
                    tooltip: 'Edit Profile',
                  ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildField('Full Name', _nameController, Icons.person_rounded, _isEditing),
            _buildDivider(),
            _buildVerifiedField(
              'Email',
              _profile['email'] ?? '',
              Icons.email_rounded,
              _profile['emailVerified'] ?? false,
            ),
            _buildDivider(),
            _buildField('Phone', _phoneController, Icons.phone_rounded, _isEditing),
          ]),
          const SizedBox(height: 24),

          // Address Section
          _buildSectionHeader('Address', Icons.location_on_outlined),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildField('Address', _addressController, Icons.home_rounded, _isEditing),
            _buildDivider(),
            _buildField('City', _cityController, Icons.location_city_rounded, _isEditing),
            _buildDivider(),
            _buildField('State', _stateController, Icons.map_rounded, _isEditing),
            _buildDivider(),
            _buildField('Pincode', _pincodeController, Icons.pin_drop_rounded, _isEditing),
          ]),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account', Icons.settings_outlined),
          const SizedBox(height: 12),
          _buildInfoCard([
            _buildInfoRow('Tenant / Organization', _profile['tenantName'] ?? '', Icons.business_rounded),
            _buildDivider(),
            _buildInfoRow(
              'Member Since',
              _formatDate(_profile['createdAt']),
              Icons.calendar_today_rounded,
            ),
          ]),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionTile(
            'Change Password',
            Icons.lock_outline_rounded,
            AppTheme.warning,
            onTap: _showChangePasswordDialog,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool editable) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                editable
                    ? TextField(
                        controller: controller,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppTheme.accent),
                          ),
                          filled: false,
                        ),
                      )
                    : Text(
                        controller.text.isEmpty ? '—' : controller.text,
                        style: TextStyle(
                          color: controller.text.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary,
                          fontSize: 15,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedField(String label, String value, IconData icon, bool verified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (verified ? AppTheme.success : AppTheme.textSecondary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  verified ? Icons.verified_rounded : Icons.pending_rounded,
                  size: 14,
                  color: verified ? AppTheme.success : AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  verified ? 'Verified' : 'Unverified',
                  style: TextStyle(
                    color: verified ? AppTheme.success : AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withValues(alpha: 0.06), height: 1);
  }

  Widget _buildActionTile(String title, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
