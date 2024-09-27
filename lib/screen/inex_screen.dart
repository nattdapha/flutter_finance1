import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String _selectedType = "Income"; // Default type
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  Future<void> addEntryHandle(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Entry"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: "Amount",
                  labelStyle: const TextStyle(color: Colors.blue),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedType,
                items: const [
                  DropdownMenuItem(value: "Income", child: Text("Income")),
                  DropdownMenuItem(value: "Expense", child: Text("Expense")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                style: const TextStyle(color: Colors.blue),
                dropdownColor: Colors.blue[50],
                underline: Container(
                  height: 2,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelText: "Note",
                  labelStyle: const TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _selectedDate) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Text(
                  "Select Date: ${_selectedDate.toLocal()}".split(' ')[0],
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('entries').add({
                  'userId': user.uid,
                  'amount': double.parse(_amountController.text),
                  'type': _selectedType,
                  'note': _noteController.text,
                  'date': _selectedDate,
                });
                _amountController.clear();
                _noteController.clear();
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: Colors.blue)),
            )
          ],
        );
      },
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/signin');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("APP FINANCE"),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('entries')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          double totalIncome = 0;
          double totalExpense = 0;

          for (var doc in snapshot.data!.docs) {
            var amount = doc['amount'] as double;
            var type = doc['type'] as String;

            if (type == 'Income') {
              totalIncome += amount;
            } else {
              totalExpense += amount;
            }
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: Colors.blue[50],
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Total Income: ฿${totalIncome.toStringAsFixed(2)}\nTotal Expense: ฿${totalExpense.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var entry = snapshot.data!.docs[index];
                    var amount = entry['amount'];
                    var note = entry['note'];
                    var type = entry['type'];
                    var date = (entry['date'] as Timestamp).toDate();

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      color: Colors.blue[50],
                      elevation: 2,
                      child: ListTile(
                        title: Text(
                          "฿${amount.toStringAsFixed(2)} - $type",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: type == "Income" ? Colors.green : Colors.red,
                          ),
                        ),
                        subtitle: Text("${date.toLocal()} - $note"),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addEntryHandle(context);
        },
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.blue[100],
    );
  }
}
