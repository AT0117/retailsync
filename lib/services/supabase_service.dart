import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';
import '../models/transaction_record.dart';


class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── Auth ────────────────────────────────────────────────────────────

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? mobileNumber,
  }) async {
    // Step 1: Create the auth user
    final AuthResponse authResponse;
    try {
      authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Auth sign-up failed: $e');
    }

    final userId = authResponse.user?.id;
    if (userId == null) {
      throw Exception('Sign-up failed: no user ID returned');
    }

    // Step 2: Sign in immediately to establish session and ensure the
    // auth.users row is fully committed (avoids FK constraint 23503).
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Auto sign-in after registration failed: $e');
    }

    // Step 3: Insert profile row using the exact UID from auth
    try {
      if (role == 'admin') {
        await _client.from('users').insert({
          'id': userId,
          'role': 'admin',
          'full_name': fullName,
        });
      } else {
        if (mobileNumber == null || mobileNumber.isEmpty) {
          throw Exception(
              'Mobile number is required for customer registration');
        }
        await _client.from('customers').insert({
          'id': userId,
          'mobile_number': mobileNumber,
          'full_name': fullName,
        });
      }
    } catch (e) {
      // Profile insert failed — auth user exists but profile doesn't.
      // Sign out to leave a clean state; user can retry.
      await _client.auth.signOut();
      throw Exception('Profile creation failed: $e');
    }

    // Return a fresh auth response with the active session
    return authResponse;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? get currentUserId => _client.auth.currentUser?.id;

  // ─── Role Detection ──────────────────────────────────────────────────

  Future<String> getUserRole(String uid) async {
    // Check users (admin) table first
    final adminResult = await _client
        .from('users')
        .select('id')
        .eq('id', uid)
        .maybeSingle();

    if (adminResult != null) return 'admin';

    // Check customers table
    final customerResult = await _client
        .from('customers')
        .select('id')
        .eq('id', uid)
        .maybeSingle();

    if (customerResult != null) return 'customer';

    throw Exception('User not found in any role table');
  }

  // ─── Customer Queries ────────────────────────────────────────────────

  Future<Customer?> getCustomerByMobile(String mobile) async {
    final result = await _client
        .from('customers')
        .select()
        .eq('mobile_number', mobile)
        .maybeSingle();

    if (result == null) return null;
    return Customer.fromMap(result);
  }

  Future<Customer?> getCustomerById(String id) async {
    final result = await _client
        .from('customers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (result == null) return null;
    return Customer.fromMap(result);
  }

  Future<List<TransactionRecord>> fetchTransactions(String customerId) async {
    final result = await _client
        .from('transactions')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (result as List)
        .map((e) => TransactionRecord.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> fetchTotalPoints(String customerId) async {
    final result = await _client
        .from('loyalty')
        .select('points_added, points_redeemed')
        .eq('customer_id', customerId);

    int total = 0;
    for (final row in result) {
      total += (row['points_added'] as num).toInt();
      total -= (row['points_redeemed'] as num).toInt();
    }
    return total;
  }

  // ─── Admin: Submit Transaction + Loyalty ─────────────────────────────

  /// Inserts a transaction, calculates points (1 pt per ₹100), inserts loyalty.
  /// Returns the number of points awarded.
  Future<int> submitTransaction({
    required String customerId,
    required String adminId,
    required double cartValue,
    required String categories,
  }) async {
    // 1. Insert transaction
    final txResult = await _client
        .from('transactions')
        .insert({
          'customer_id': customerId,
          'processed_by': adminId,
          'cart_value': cartValue,
          'categories': categories,
        })
        .select('id')
        .single();

    final transactionId = txResult['id'] as String;

    // 2. Calculate points: 1 point per ₹100 spent
    final pointsEarned = (cartValue / 100).floor();

    // 3. Insert loyalty record
    await _client.from('loyalty').insert({
      'customer_id': customerId,
      'points_added': pointsEarned,
      'points_redeemed': 0,
      'transaction_id': transactionId,
    });

    return pointsEarned;
  }
}
