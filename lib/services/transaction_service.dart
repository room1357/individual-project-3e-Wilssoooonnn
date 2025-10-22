import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pemrograman_mobile/models/transaction_model.dart';

class TransactionService {
  static const String _kTransactionsKey = 'transactions_database';

  // Helper untuk mengambil semua transaksi
  static Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? txsString = prefs.getString(_kTransactionsKey);

    if (txsString == null) {
      return []; // Kembalikan list kosong jika belum ada data
    }

    // Ubah String JSON menjadi List<Map>
    final List<dynamic> txsList = jsonDecode(txsString);

    // Ubah setiap Map menjadi object Transaction
    return txsList.map((json) => Transaction.fromJson(json)).toList();
  }

  // Helper untuk menyimpan list transaksi
  static Future<void> _saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    // Ubah List<Transaction> menjadi List<Map>
    final List<Map<String, dynamic>> txsList =
        transactions.map((tx) => tx.toJson()).toList();

    // Ubah List<Map> menjadi String JSON
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
    // Cari index dari transaksi lama berdasarkan ID-nya
    final int index = transactions.indexWhere((tx) => tx.id == updatedTx.id);
    if (index != -1) {
      transactions[index] = updatedTx; // Ganti dengan data baru
      await _saveTransactions(transactions);
    }
  }

  // DELETE (D)
  static Future<void> deleteTransaction(String id) async {
    final List<Transaction> transactions = await getTransactions();
    transactions.removeWhere((tx) => tx.id == id); // Hapus berdasarkan ID
    await _saveTransactions(transactions);
  }
}
