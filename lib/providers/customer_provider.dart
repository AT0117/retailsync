import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_record.dart';
import 'auth_provider.dart';

// ─── Total Loyalty Points ──────────────────────────────────────────────

final customerPointsProvider = FutureProvider.autoDispose<int>((ref) async {
  final service = ref.read(supabaseServiceProvider);
  final authState = ref.watch(authProvider);
  if (authState.userId == null) return 0;
  return service.fetchTotalPoints(authState.userId!);
});

// ─── Transaction History ───────────────────────────────────────────────

final customerTransactionsProvider =
    FutureProvider.autoDispose<List<TransactionRecord>>((ref) async {
  final service = ref.read(supabaseServiceProvider);
  final authState = ref.watch(authProvider);
  if (authState.userId == null) return [];
  return service.fetchTransactions(authState.userId!);
});
