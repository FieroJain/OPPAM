import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/firebase_service.dart';
import '../../../core/utils/phone_utils.dart';
import '../../auth/cubit/auth_cubit.dart';

/// Emergency contacts screen — loads from Firebase, supports add/delete/call.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final FirebaseService _firebase = FirebaseService();
  List<Map<String, dynamic>> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _loading = true);
    final userId = context.read<AuthCubit>().state.userId ?? 'default_user';
    final contacts = await _firebase.getContacts(userId);
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(context),
                    _buildHeader(),
                    _buildContactList(),
                    _buildAddContactButton(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Emergency Contacts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: _showAddContactDialog,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 16),
          const Text(
            'Your Circle',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _contacts.isEmpty
                ? 'No contacts yet. Tap + to add your first emergency contact.'
                : '${_contacts.length} contact(s) saved. '
                    'Tap the phone icon to call.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList() {
    if (_contacts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline,
                  color: AppColors.textTertiary, size: 56),
              const SizedBox(height: 12),
              Text(
                'No emergency contacts',
                style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: _contacts
            .map((contact) => _ContactCard(
                  contact: contact,
                  onCall: () => _callContact(contact),
                  onDelete: () => _deleteContact(contact),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAddContactButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: GestureDetector(
        onTap: _showAddContactDialog,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textTertiary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.person_add, color: AppColors.textTertiary, size: 28),
              const SizedBox(height: 8),
              Text(
                'Add another contact',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callContact(Map<String, dynamic> contact) async {
    final rawPhone = contact['phone']?.toString() ?? '';
    if (rawPhone.isEmpty) return;
    final dialNumber = cleanPhoneForDial(rawPhone);
    final uri = Uri.parse('tel:$dialNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open dialer for $dialNumber'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _deleteContact(Map<String, dynamic> contact) async {
    final contactId = contact['id']?.toString();
    if (contactId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Contact?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Remove ${contact['name']} from emergency contacts?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final userId =
          context.read<AuthCubit>().state.userId ?? 'default_user';
      await _firebase.deleteContact(userId: userId, contactId: contactId);
      _loadContacts();
    }
  }

  void _showAddContactDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final roleController = TextEditingController();
    String selectedPriority = 'high';
    String? phoneError;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.glassBorderLight),
          ),
          title: const Text(
            'Add Emergency Contact',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDialogField(nameController, 'Full Name',
                      Icons.person),
                  const SizedBox(height: 12),
                  // Phone field with validation
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    validator: validatePhone,
                    onChanged: (_) {
                      if (phoneError != null) {
                        setDialogState(() => phoneError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      hintStyle: TextStyle(color: AppColors.textTertiary),
                      errorText: phoneError,
                      prefixIcon: Icon(Icons.phone,
                          color: AppColors.textTertiary, size: 20),
                      filled: true,
                      fillColor: AppColors.surfaceDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accent),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.danger),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDialogField(roleController, 'Role (e.g. Son, Doctor)',
                      Icons.badge),
                  const SizedBox(height: 16),
                  // Priority selector
                  Row(
                    children: [
                      Text('Priority: ',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 8),
                      _priorityChip('high', 'High', AppColors.danger,
                          selectedPriority, (v) {
                        setDialogState(() => selectedPriority = v);
                      }),
                      const SizedBox(width: 6),
                      _priorityChip('family', 'Family', AppColors.warning,
                          selectedPriority, (v) {
                        setDialogState(() => selectedPriority = v);
                      }),
                      const SizedBox(width: 6),
                      _priorityChip('caregiver', 'Care', AppColors.accent,
                          selectedPriority, (v) {
                        setDialogState(() => selectedPriority = v);
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel',
                  style: TextStyle(color: AppColors.textTertiary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                // Validate phone
                final phoneErr = validatePhone(phoneController.text.trim());
                if (phoneErr != null) {
                  setDialogState(() => phoneError = phoneErr);
                  return;
                }
                Navigator.pop(dialogContext);
                _saveContact(
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  role: roleController.text.trim().isEmpty
                      ? 'Contact'
                      : roleController.text.trim(),
                  priority: selectedPriority,
                );
              },
              child: const Text('SAVE',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textTertiary, size: 20),
        filled: true,
        fillColor: AppColors.surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _priorityChip(String value, String label, Color color,
      String selected, ValueChanged<String> onTap) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : AppColors.textTertiary.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _saveContact({
    required String name,
    required String phone,
    required String role,
    required String priority,
  }) async {
    final userId =
        context.read<AuthCubit>().state.userId ?? 'default_user';
    // Store phone in consistent +91XXXXXXXXXX format
    final cleanedPhone = cleanForStorage(phone);
    await _firebase.saveContact(
      userId: userId,
      name: name,
      phone: cleanedPhone,
      role: role,
      priority: priority,
    );
    _loadContacts();
  }
}

// ── Contact Card Widget ────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onCall;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onCall,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (contact['priority']?.toString() ?? '') {
      case 'high':
        return AppColors.danger;
      case 'family':
        return AppColors.warning;
      case 'caregiver':
        return AppColors.accent;
      default:
        return AppColors.textTertiary;
    }
  }

  String get _priorityLabel {
    switch (contact['priority']?.toString() ?? '') {
      case 'high':
        return 'HIGH';
      case 'family':
        return 'FAMILY';
      case 'caregiver':
        return 'CAREGIVER';
      default:
        return 'OTHER';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = contact['name']?.toString() ?? 'Unknown';
    final phone = contact['phone']?.toString() ?? '';
    final role = contact['role']?.toString() ?? 'Contact';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Color bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _priorityColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Avatar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: _priorityColor.withValues(alpha: 0.2),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: _priorityColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _priorityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _priorityLabel,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _priorityColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$role • ${formatPhone(phone)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              // Call button
              IconButton(
                onPressed: onCall,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call,
                      color: AppColors.accent, size: 18),
                ),
              ),
              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline,
                    color: AppColors.textTertiary, size: 20),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
