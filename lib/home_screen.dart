import 'package:flutter/material.dart';
import 'package:test2/repository/note_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _showArchived = false; // Flag to show archived notes

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  // Fetch notes based on the showArchived flag
  Future<void> _fetchNotes() async {
    final notes = await DBHelper.instance.getNotes(archived: _showArchived);
    setState(() {
      _notes = notes ?? [];
    });
  }

  // Add or edit note
  Future<void> _addOrEditNote({Map<String, dynamic>? note}) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedPriority = note?['priority'] ?? 'High';

    if (note != null) {
      titleController.text = note['title'] ?? '';
      contentController.text = note['content'] ?? '';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            note == null ? 'Add Note' : 'Edit Note',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Priority', style: TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          _priorityColorOption(
                            Colors.green, 'Low', selectedPriority, (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }),
                          _priorityColorOption(
                            Colors.orange, 'Medium', selectedPriority, (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }),
                          _priorityColorOption(
                            Colors.red, 'High', selectedPriority, (value) {
                            setState(() {
                              selectedPriority = value;
                            });
                          }),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color.fromARGB(255, 17, 17, 17))),
            ),
            ElevatedButton(
              onPressed: () async {
                final newNote = {
                  'title': titleController.text,
                  'content': contentController.text,
                  'priority': selectedPriority,
                  'archived': note?['archived'] ?? 0,
                  if (note != null) 'id': note['id'],
                };

                if (note == null) {
                  await _addNote(newNote);
                } else {
                  await _updateNote(newNote);
                }

                Navigator.of(context).pop();
                _fetchNotes();
              },
              child: Text(note == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNote(Map<String, dynamic> note) async {
    await DBHelper.instance.insertNote(note);
  }

  Future<void> _updateNote(Map<String, dynamic> note) async {
    await DBHelper.instance.updateNote(note);
  }

  // Delete note dialog
  Future<void> _deleteNoteDialog(int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Note', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await DBHelper.instance.deleteNote(id);
              Navigator.of(context).pop();
              _fetchNotes();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Get priority color
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get card color for each note
  Color _getCardColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.withOpacity(0.1);
      case 'Medium':
        return Colors.orange.withOpacity(0.1);
      case 'Low':
        return Colors.green.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  // Priority color option widget
  Widget _priorityColorOption(Color color, String priority, String selectedPriority, Function(String) onTap) {
    return GestureDetector(
      onTap: () => onTap(priority),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selectedPriority == priority
              ? Border.all(color: Colors.black, width: 2)
              : null,
        ),
        width: 24,
        height: 24,
      ),
    );
  }

  // Archive or unarchive note
  Future<void> _archiveOrUnarchiveNote(int id, bool archived) async {
    await DBHelper.instance.archiveOrUnarchiveNote(id, !archived);
    _fetchNotes(); // Refresh the notes after updating
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 246, 238, 5),
        actions: [
          IconButton(
            icon: Icon(_showArchived ? Icons.archive : Icons.unarchive),
            onPressed: () {
              setState(() {
                _showArchived = !_showArchived;
                _fetchNotes();
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _notes.isEmpty
            ? const Center(child: Text('No Notes Found', style: TextStyle(fontSize: 18)))
            : ListView.builder(
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  return Card(
                    color: _getCardColor(note['priority'] ?? 'Medium'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(10),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              note['title'] ?? 'Untitled',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(note['priority'] ?? 'Medium'),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              note['priority'] ?? 'Medium',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          note['content'] ?? 'No content',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(note['archived'] == 1 ? Icons.archive : Icons.unarchive),
                            onPressed: () => _archiveOrUnarchiveNote(note['id'], note['archived'] == 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _addOrEditNote(note: note),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteNoteDialog(note['id']),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      // Conditionally show the FloatingActionButton
      floatingActionButton: _showArchived
          ? null
          : FloatingActionButton(
              onPressed: () => _addOrEditNote(),
              child: const Icon(Icons.add),
            ),
    );
  }
}
