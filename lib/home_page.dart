import 'package:flutter/material.dart';
import 'package:sqflite_delacruz/sql_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> notes = [];
  bool _isLoading = true;

  void getNotes() async {
    final data = await SQLHelper.getItems();
    setState(() {
      notes = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getNotes(); // Loading the diary when the app starts
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          notes.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 10,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                // this will prevent the soft keyboard from covering the text fields
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(hintText: 'Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter your Name';
                          } else {
                            return null;
                          }
                        }),
                    const SizedBox(
                      height: 10,
                    ),
                    TextFormField(
                        controller: _descriptionController,
                        keyboardType: const TextInputType.numberWithOptions(),
                        decoration: const InputDecoration(hintText: 'Amount'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please Enter the Amount';
                          } else {
                            return null;
                          }
                        }),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          if (id == null) {
                            await _addItem();
                          }

                          if (id != null) {
                            await _updateItem(id);
                          }

                          _titleController.text = '';
                          _descriptionController.text = '';

                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(id == null ? 'Create New' : 'Update'),
                    )
                  ],
                ),
              ),
            ));
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _titleController.text, _descriptionController.text);
    getNotes();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text, _descriptionController.text);
    getNotes();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a journal!'),
    ));
    getNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List of Debt'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final name = notes[index]['title'];
                final value = notes[index]['description']; 
                return Dismissible(
                background: Container(
                  color: Colors.red,
                  child: const Icon(Icons.delete_forever),
                ),
                secondaryBackground: Container(
                  color: Colors.green,
                  child: const Icon(Icons.update),
                ),
                key: UniqueKey(),
                onDismissed: (direction) {
                  if(direction == DismissDirection.startToEnd){
                    _deleteItem(notes[index]['id']);
                  }
                  else if(direction == DismissDirection.endToStart){
                    _showForm(notes[index]['id']);
                  }
                },
                child: Card(
                  color: const Color.fromARGB(255, 20, 8, 56),
                  child: ListTile(
                      leading: const Icon(Icons.person_2),
                      title: Text('Name: $name'),
                      subtitle: Text('Amount: ₱$value.00'),
                      ),
                ),
              );
              }
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
