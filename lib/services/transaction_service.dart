import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pemrograman_mobile/models/transaction_model.dart';

class TransactionService {
  static const String _kTransactionsKey = 'transactions_database';

  static Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? txsString = prefs.getString(_kTransactionsKey);

    if (txsString == null) {
      return [];
    }

    final List<dynamic> txsList = jsonDecode(txsString);

    return txsList.map((json) => Transaction.fromJson(json)).toList();
  }

  static Future<void> _saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> txsList =
        transactions.map((tx) => tx.toJson()).toList();

    final String txsString = jsonEncode(txsList);
    await prefs.setString(_kTransactionsKey, txsString);
  }

  // CREATE (C)
  static Future<void> addTransaction(Transaction tx) async {
    final List<Transaction> transactions = await getTransactions();
    transactions.add(tx);
    await _saveTransactions(transactions);
  }

  // UPDATE (U)
  static Future<void> updateTransaction(Transaction updatedTx) async {
    final List<Transaction> transactions = await getTransactions();
    final int index = transactions.indexWhere((tx) => tx.id == updatedTx.id);
    if (index != -1) {
      transactions[index] = updatedTx;
      await _saveTransactions(transactions);
    }
  }

  // DELETE (D)
  static Future<void> deleteTransaction(String id) async {
    final List<Transaction> transactions = await getTransactions();
    transactions.removeWhere((tx) => tx.id == id);
    await _saveTransactions(transactions);
  }
}
