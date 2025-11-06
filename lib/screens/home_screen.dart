import 'package:flutter/material.dart';
import 'package:pemrograman_mobile/models/transaction_model.dart';
import 'package:pemrograman_mobile/screens/add_edit_transaction_screen.dart';
import 'package:pemrograman_mobile/screens/login_screen.dart';
import 'package:pemrograman_mobile/services/transaction_service.dart';
import 'package:intl/intl.dart';

enum TimeFilter { all, today, week, month }

enum TransactionFilter { all, income, expense }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;

  double _allTimeBalance = 0.0;
  double _filteredIncome = 0.0;
  double _filteredExpense = 0.0;

  TimeFilter _selectedTimeFilter = TimeFilter.all;
  TransactionFilter _selectedTransactionFilter = TransactionFilter.all;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final transactions = await TransactionService.getTransactions();
    transactions.sort((a, b) => b.date.compareTo(a.date));

    double allTimeBalance = 0.0;
    for (var tx in transactions) {
      if (tx.type == TransactionType.income) {
        allTimeBalance += tx.amount;
      } else {
        allTimeBalance -= tx.amount;
      }
    }

    setState(() {
      _allTransactions = transactions;
      _allTimeBalance = allTimeBalance;
      _isLoading = false;
    });

    _applyFilters();
  }

  void _applyFilters() {
    final now = DateTime.now();
    List<Transaction> timeFilteredList = [];

    switch (_selectedTimeFilter) {
      case TimeFilter.today:
        timeFilteredList =
            _allTransactions.where((tx) {
              return _isSameDay(tx.date, now);
            }).toList();
        break;
      case TimeFilter.week:
        timeFilteredList =
            _allTransactions.where((tx) {
              return _isSameWeek(tx.date, now);
            }).toList();
        break;
      case TimeFilter.month:
        timeFilteredList =
            _allTransactions.where((tx) {
              return _isSameMonth(tx.date, now);
            }).toList();
        break;
      case TimeFilter.all:
      default:
        timeFilteredList = List.from(_allTransactions);
        break;
    }

    List<Transaction> finalFilteredList = [];
    switch (_selectedTransactionFilter) {
      case TransactionFilter.income:
        finalFilteredList =
            timeFilteredList
                .where((tx) => tx.type == TransactionType.income)
                .toList();
        break;
      case TransactionFilter.expense:
        finalFilteredList =
            timeFilteredList
                .where((tx) => tx.type == TransactionType.expense)
                .toList();
        break;
      case TransactionFilter.all:
      default:
        finalFilteredList = timeFilteredList;
        break;
    }

    double filteredIncome = 0.0;
    double filteredExpense = 0.0;
    for (var tx in finalFilteredList) {
      if (tx.type == TransactionType.income) {
        filteredIncome += tx.amount;
      } else {
        filteredExpense += tx.amount;
      }
    }

    setState(() {
      _filteredTransactions = finalFilteredList;
      _filteredIncome = filteredIncome;
      _filteredExpense = filteredExpense;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  bool _isSameWeek(DateTime a, DateTime b) {
    final aMonday = _getMonday(a);
    final bMonday = _getMonday(b);
    return _isSameDay(aMonday, bMonday);
  }

  Future<void> _deleteTransaction(String id) async {
    await TransactionService.deleteTransaction(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _loadData();
  }

  void _navigateToAddScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTransactionScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _navigateToEditScreen(Transaction transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => AddEditTransactionScreen(transaction: transaction),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _buildBalanceCard(),
                    ),
                    _buildTimeFilterSegment(),
                    const SizedBox(height: 16),
                    _buildTransactionFilterSegment(),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildRecentTransactions(),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddScreen,
        backgroundColor: Colors.blue,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      elevation: 6,
      color: Colors.blue[700],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Balance',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              _currencyFormat.format(_allTimeBalance),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _currencyFormat.format(_filteredIncome),
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _currencyFormat.format(_filteredExpense),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterSegment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SegmentedButton<TimeFilter>(
        segments: const [
          ButtonSegment(value: TimeFilter.all, label: Text('All')),
          ButtonSegment(value: TimeFilter.today, label: Text('Day')),
          ButtonSegment(value: TimeFilter.week, label: Text('Week')),
          ButtonSegment(value: TimeFilter.month, label: Text('Month')),
        ],
        selected: {_selectedTimeFilter},
        onSelectionChanged: (Set<TimeFilter> newSelection) {
          setState(() {
            _selectedTimeFilter = newSelection.first;
            _applyFilters();
          });
        },
        style: SegmentedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTransactionFilterSegment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SegmentedButton<TransactionFilter>(
        segments: const [
          ButtonSegment(
            value: TransactionFilter.all,
            label: Text('All'),
            icon: Icon(Icons.list_alt),
          ),
          ButtonSegment(
            value: TransactionFilter.income,
            label: Text('Income'),
            icon: Icon(Icons.arrow_downward, color: Colors.green),
          ),
          ButtonSegment(
            value: TransactionFilter.expense,
            label: Text('Expense'),
            icon: Icon(Icons.arrow_upward, color: Colors.red),
          ),
        ],
        selected: {_selectedTransactionFilter},
        onSelectionChanged: (Set<TransactionFilter> newSelection) {
          setState(() {
            _selectedTransactionFilter = newSelection.first;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_filteredTransactions.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'No transactions found for this filter.\nPress "+" to add one!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _filteredTransactions.length,
        itemBuilder: (context, index) {
          final tx = _filteredTransactions[index];
          final bool isExpense = tx.type == TransactionType.expense;
          final String formattedAmount = _currencyFormat.format(tx.amount);

          return Dismissible(
            key: Key(tx.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _deleteTransaction(tx.id);
            },
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isExpense ? Colors.red[100] : Colors.green[100],
                  child: Icon(
                    tx.icon,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
                title: Text(
                  tx.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(DateFormat.yMMMd().format(tx.date)),
                trailing: Text(
                  isExpense ? '-$formattedAmount' : '+$formattedAmount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isExpense ? Colors.red : Colors.green,
                  ),
                ),
                onTap: () {
                  _navigateToEditScreen(tx);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  'Welcome User!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
