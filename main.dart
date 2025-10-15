import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo Firebase App',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
      ),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _taskController = TextEditingController();

  Future<void> addTodo() async {
    if (_taskController.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('todos').add({
      'task': _taskController.text,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _taskController.clear();
  }

  Future<void> toggleCompleted(String docId, bool currentValue) async {
    await FirebaseFirestore.instance.collection('todos').doc(docId).update({
      'completed': !currentValue,
    });
  }

  Future<void> deleteTodo(String docId) async {
    await FirebaseFirestore.instance.collection('todos').doc(docId).delete();
  }

  String formatTimestamp(Timestamp? timestamp) {
    final date = (timestamp ?? Timestamp.fromDate(DateTime.now())).toDate();
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todo List'),
        centerTitle: true,
        backgroundColor: Colors.purpleAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Enter a new task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: addTodo,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('todos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No todos yet.'));
                }

                final todos = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final doc = todos[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final task = data['task'] ?? '';
                    final completed = data['completed'] ?? false;
                    final createdAt = data['createdAt'] as Timestamp?;

                    return ListTile(
                      leading: Checkbox(
                        value: completed,
                        onChanged: (val) => toggleCompleted(doc.id, completed),
                      ),
                      title: Text(
                        task,
                        style: TextStyle(
                          decoration: completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle: Text(
                        formatTimestamp(createdAt),
                        style: TextStyle(color: Colors.purple[600]),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.purple),
                        onPressed: () => deleteTodo(doc.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
