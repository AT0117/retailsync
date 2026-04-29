import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// ─── Customer Lookup State ─────────────────────────────────────────────

enum LookupStatus { idle, loading, found, notFound, error }

class CustomerLookupState {
  final LookupStatus status;
  final Customer? customer;
  final String? errorMessage;

  const CustomerLookupState({
    this.status = LookupStatus.idle,
    this.customer,
    this.errorMessage,
  });
}

class CustomerLookupNotifier extends StateNotifier<CustomerLookupState> {
  final SupabaseService _service;

  CustomerLookupNotifier(this._service)
      : super(const CustomerLookupState());

  Future<void> lookupByMobile(String mobile) async {
    state = const CustomerLookupState(status: LookupStatus.loading);
    try {
      final customer = await _service.getCustomerByMobile(mobile);
      if (customer == null) {
        state = const CustomerLookupState(status: LookupStatus.notFound);
      } else {
        state = CustomerLookupState(
          status: LookupStatus.found,
          customer: customer,
        );
      }
    } catch (e) {
      state = CustomerLookupState(
        status: LookupStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> lookupById(String id) async {
    state = const CustomerLookupState(status: LookupStatus.loading);
    try {
      final customer = await _service.getCustomerById(id);
      if (customer == null) {
        state = const CustomerLookupState(status: LookupStatus.notFound);
      } else {
        state = CustomerLookupState(
          status: LookupStatus.found,
          customer: customer,
        );
      }
    } catch (e) {
      state = CustomerLookupState(
        status: LookupStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const CustomerLookupState();
  }
}

// ─── Transaction Submission State ──────────────────────────────────────

enum SubmitStatus { idle, loading, success, error }

class TransactionSubmitState {
  final SubmitStatus status;
  final int? pointsAwarded;
  final String? errorMessage;

  const TransactionSubmitState({
    this.status = SubmitStatus.idle,
    this.pointsAwarded,
    this.errorMessage,
  });
}

class TransactionSubmitNotifier extends StateNotifier<TransactionSubmitState> {
  final SupabaseService _service;

  TransactionSubmitNotifier(this._service)
      : super(const TransactionSubmitState());

  Future<void> submit({
    required String customerId,
    required String adminId,
    required double cartValue,
    required String categories,
  }) async {
    state = const TransactionSubmitState(status: SubmitStatus.loading);
    try {
      final points = await _service.submitTransaction(
        customerId: customerId,
        adminId: adminId,
        cartValue: cartValue,
        categories: categories,
      );
      state = TransactionSubmitState(
        status: SubmitStatus.success,
        pointsAwarded: points,
      );
    } catch (e) {
      state = TransactionSubmitState(
        status: SubmitStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const TransactionSubmitState();
  }
}

// ─── Providers ──────────────────────────────────────────────────────────

final customerLookupProvider =
    StateNotifierProvider<CustomerLookupNotifier, CustomerLookupState>((ref) {
  final service = ref.read(supabaseServiceProvider);
  return CustomerLookupNotifier(service);
});

final transactionSubmitProvider =
    StateNotifierProvider<TransactionSubmitNotifier, TransactionSubmitState>(
        (ref) {
  final service = ref.read(supabaseServiceProvider);
  return TransactionSubmitNotifier(service);
});
