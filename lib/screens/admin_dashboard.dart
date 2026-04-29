import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/notification_banner.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  final _mobileController = TextEditingController();
  final _cartValueController = TextEditingController();
  final _categoriesController = TextEditingController();
  final _txFormKey = GlobalKey<FormState>();

  bool _showNotification = false;
  int _notificationPoints = 0;
  String _notificationCustomer = '';

  @override
  void dispose() {
    _mobileController.dispose();
    _cartValueController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  void _lookupCustomer() {
    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a mobile number'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    ref.read(customerLookupProvider.notifier).lookupByMobile(mobile);
  }

  Future<void> _scanQR() async {
    final scannedId = await Navigator.pushNamed(context, '/qr-scanner');
    if (scannedId != null && scannedId is String && scannedId.isNotEmpty) {
      ref.read(customerLookupProvider.notifier).lookupById(scannedId);
    }
  }

  void _submitTransaction() {
    if (!_txFormKey.currentState!.validate()) return;
    final lookupState = ref.read(customerLookupProvider);
    if (lookupState.customer == null) return;
    final authState = ref.read(authProvider);

    ref.read(transactionSubmitProvider.notifier).submit(
          customerId: lookupState.customer!.id,
          adminId: authState.userId!,
          cartValue: double.parse(_cartValueController.text.trim()),
          categories: _categoriesController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lookupState = ref.watch(customerLookupProvider);
    final submitState = ref.watch(transactionSubmitProvider);

    // Listen for successful transaction submission
    ref.listen<TransactionSubmitState>(transactionSubmitProvider, (prev, next) {
      if (next.status == SubmitStatus.success) {
        final customerName =
            ref.read(customerLookupProvider).customer?.fullName ?? 'Customer';
        setState(() {
          _showNotification = true;
          _notificationPoints = next.pointsAwarded ?? 0;
          _notificationCustomer = customerName;
        });
        _cartValueController.clear();
        _categoriesController.clear();
        ref.read(transactionSubmitProvider.notifier).reset();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Transaction recorded! $customerName earned ${next.pointsAwarded} points.'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else if (next.status == SubmitStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Transaction failed'),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer Lookup ──
                _buildSectionHeader(
                    theme, 'Customer Lookup', Icons.person_search_rounded),
                const SizedBox(height: 14),
                _buildLookupSection(theme, lookupState),
                const SizedBox(height: 28),

                // ── New Transaction (only if customer found) ──
                if (lookupState.status == LookupStatus.found) ...[
                  _buildSectionHeader(
                      theme, 'New Transaction', Icons.point_of_sale_rounded),
                  const SizedBox(height: 14),
                  _buildTransactionForm(theme, lookupState, submitState),
                ],
              ],
            ),
          ),

          // ── Notification Banner Overlay ──
          if (_showNotification)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: NotificationBanner(
                  message: 'Points awarded to $_notificationCustomer',
                  points: _notificationPoints,
                  onDismissed: () => setState(() => _showNotification = false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildLookupSection(ThemeData theme, CustomerLookupState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mobileController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter mobile number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: state.status == LookupStatus.loading
                    ? null
                    : _lookupCustomer,
                icon: const Icon(Icons.search_rounded, size: 20),
                label: const Text('Find'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanQR,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan QR Code'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Result display
          if (state.status == LookupStatus.loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (state.status == LookupStatus.found && state.customer != null)
            _buildCustomerCard(theme, state),
          if (state.status == LookupStatus.notFound)
            _buildStatusMessage(
              theme,
              Icons.person_off_rounded,
              'Customer not found',
              'No account exists with this identifier.',
              theme.colorScheme.error,
            ),
          if (state.status == LookupStatus.error)
            _buildStatusMessage(
              theme,
              Icons.error_outline_rounded,
              'Lookup failed',
              state.errorMessage ?? 'An error occurred.',
              theme.colorScheme.error,
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(ThemeData theme, CustomerLookupState state) {
    final customer = state.customer!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              customer.fullName.isNotEmpty
                  ? customer.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.mobileNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade600, size: 28),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: color, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionForm(
    ThemeData theme,
    CustomerLookupState lookupState,
    TransactionSubmitState submitState,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Form(
        key: _txFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer info chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_rounded,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    lookupState.customer?.fullName ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _cartValueController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Cart Value (₹)',
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter cart value';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                if (double.parse(v) <= 0) return 'Must be greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoriesController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Categories',
                hintText: 'e.g. Groceries, Electronics',
                prefixIcon: const Icon(Icons.category_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Enter categories' : null,
            ),
            const SizedBox(height: 10),
            // Points preview
            Builder(builder: (_) {
              final text = _cartValueController.text;
              final val = double.tryParse(text);
              if (val != null && val > 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Points to be awarded: ${(val / 100).floor()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: submitState.status == SubmitStatus.loading
                    ? null
                    : _submitTransaction,
                icon: submitState.status == SubmitStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(
                  submitState.status == SubmitStatus.loading
                      ? 'Processing...'
                      : 'Submit Transaction',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
