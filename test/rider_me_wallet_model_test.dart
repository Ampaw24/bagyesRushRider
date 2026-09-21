import 'package:delivery_boy/features/rider/wallet/models/rider_me_wallet_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RiderMeWalletModel.fromJson', () {
    test('parses numeric balances', () {
      final wallet = RiderMeWalletModel.fromJson({
        'balance': 120.5,
        'available_balance': 100,
        'pending_balance': 20.5,
        'currency': 'GHS',
      });
      expect(wallet.balance, 120.5);
      expect(wallet.availableBalance, 100);
      expect(wallet.pendingBalance, 20.5);
      expect(wallet.balanceFormatted, 'GHS 120.50');
    });

    test('parses balances arriving as numeric strings without throwing', () {
      final wallet = RiderMeWalletModel.fromJson({
        'balance': '250.75',
        'available_balance': '250.75',
      });
      expect(wallet.balance, 250.75);
      expect(wallet.availableBalance, 250.75);
    });

    test('defaults balance to 0 and currency to GHS when absent', () {
      final wallet = RiderMeWalletModel.fromJson({});
      expect(wallet.balance, 0);
      expect(wallet.currency, 'GHS');
    });
  });

  group('RiderMeWalletTransactionModel.fromJson', () {
    test('parses an id and amount arriving as numeric strings', () {
      final tx = RiderMeWalletTransactionModel.fromJson({
        'id': '42',
        'amount': '18.50',
        'type': 'credit',
      });
      expect(tx.id, 42);
      expect(tx.amount, 18.5);
    });

    test('classifies known credit types, including bonus', () {
      for (final type in ['credit', 'admin_credit', 'bonus', 'compensation']) {
        final tx = RiderMeWalletTransactionModel.fromJson(
            {'id': 1, 'type': type, 'amount': 10});
        expect(tx.direction, RiderMeWalletTxDirection.credit, reason: type);
      }
    });

    test('classifies known debit types', () {
      for (final type in ['debit', 'admin_debit']) {
        final tx = RiderMeWalletTransactionModel.fromJson(
            {'id': 1, 'type': type, 'amount': 10});
        expect(tx.direction, RiderMeWalletTxDirection.debit, reason: type);
      }
    });

    test('falls back to the amount sign for an undocumented type', () {
      final credit = RiderMeWalletTransactionModel.fromJson(
          {'id': 1, 'type': 'referral_bonus', 'amount': 5});
      expect(credit.direction, RiderMeWalletTxDirection.credit);

      final debit = RiderMeWalletTransactionModel.fromJson(
          {'id': 2, 'type': 'referral_bonus', 'amount': -5});
      expect(debit.direction, RiderMeWalletTxDirection.debit);
    });

    test('is unknown when there is neither a known type nor a signed amount',
        () {
      final tx = RiderMeWalletTransactionModel.fromJson({'id': 1});
      expect(tx.direction, RiderMeWalletTxDirection.unknown);
    });
  });

  group('RiderMeWithdrawalModel.fromJson', () {
    test('parses id/amount arriving as numeric strings', () {
      final withdrawal = RiderMeWithdrawalModel.fromJson({
        'id': '7',
        'amount': '250.00',
        'status': 'pending',
      });
      expect(withdrawal.id, 7);
      expect(withdrawal.amount, 250.0);
      expect(withdrawal.isCancellable, isTrue);
    });

    test('is only cancellable while pending', () {
      for (final status in ['approved', 'paid', 'rejected', 'cancelled', 'reversed']) {
        final withdrawal =
            RiderMeWithdrawalModel.fromJson({'id': 1, 'amount': 10, 'status': status});
        expect(withdrawal.isCancellable, isFalse, reason: status);
      }
    });
  });
}
