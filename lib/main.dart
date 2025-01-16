import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const MyApp());
}

class Task {
  String id;
  String title;
  String category;
  bool isCompleted;
  DateTime date;

  Task({
    required this.title,
    required this.category,
    this.isCompleted = false,
    required this.date,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'SF Pro Display',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Task> _tasks = [];
  int _selectedIndex = 0; // "All Tasks" page as default
  DateTime _selectedDay = DateTime.now();

  void _addTask(String title, String category, DateTime date) {
    setState(() {
      _tasks.add(Task(
        title: title,
        category: category,
        date: date,
      ));
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.remove(task);
    });
  }

  void _toggleTask(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
    });
  }

  List<Task> _getTasksForDate(DateTime date) {
    return _tasks.where((task) {
      return isSameDay(task.date, date);
    }).toList();
  }

  Map<String, int> _getCategoryCounts(DateTime date) {
    final tasksForDate = _getTasksForDate(date);
    final counts = <String, int>{};
    for (var task in tasksForDate) {
      counts[task.category] = (counts[task.category] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AllTasksPage(
            tasks: _tasks,
            categoryCounts: _getCategoryCounts(_selectedDay),
            onDeleteTask: _deleteTask,
            onToggleTask: _toggleTask,
          ),
          CalendarPage(
            tasks: _tasks,
            selectedDay: _selectedDay,
            onDaySelected: (day) {
              setState(() {
                _selectedDay = day;
                _selectedIndex = 1; // Switch to "Calendar" view
              });
            },
          ),
          TodayPage(
            tasks: _getTasksForDate(_selectedDay),
            categoryCounts: _getCategoryCounts(_selectedDay),
            onDeleteTask: _deleteTask,
            onToggleTask: _toggleTask,
            selectedDate: _selectedDay,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => NewTaskSheet(onAddTask: _addTask),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'All Tasks', // "All Tasks" is the main page
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Today',
          ),
        ],
      ),
    );
  }
}

class TodayPage extends StatelessWidget {
  final List<Task> tasks;
  final Map<String, int> categoryCounts;
  final Function(Task) onDeleteTask;
  final Function(Task) onToggleTask;
  final DateTime selectedDate;

  const TodayPage({
    super.key,
    required this.tasks,
    required this.categoryCounts,
    required this.onDeleteTask,
    required this.onToggleTask,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Today ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('d MMM').format(selectedDate),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CategoryChip(
                  icon: Icons.favorite,
                  label: 'Health',
                  count: categoryCounts['Health'] ?? 0,
                  color: Colors.blue,
                ),
                _CategoryChip(
                  icon: Icons.work,
                  label: 'Work',
                  count: categoryCounts['Work'] ?? 0,
                  color: Colors.green,
                ),
                _CategoryChip(
                  icon: Icons.psychology,
                  label: 'Mental Health',
                  count: categoryCounts['Mental Health'] ?? 0,
                  color: Colors.purple,
                ),
                _CategoryChip(
                  icon: Icons.more_horiz,
                  label: 'Others',
                  count: categoryCounts['Others'] ?? 0,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks for today',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Dismissible(
                          key: Key(task.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => onDeleteTask(task),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: _TaskItem(
                            task: task,
                            onToggle: () => onToggleTask(task),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _CategoryChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color)),
          const SizedBox(width: 4),
          Text('$count', style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;

  const _TaskItem({
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.blue)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  task.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarPage extends StatelessWidget {
  final List<Task> tasks;
  final DateTime selectedDay;
  final Function(DateTime) onDaySelected;

  const CalendarPage({
    super.key,
    required this.tasks,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Calendar ',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  DateFormat('d MMM').format(selectedDay),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TableCalendar(
              firstDay:
                  DateTime.utc(currentYear, 1, 1), // Start of current year
              lastDay: DateTime.utc(currentYear, 12, 31), // End of current year
              focusedDay: selectedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                onDaySelected(selectedDay);
              },
              eventLoader: (day) {
                return tasks
                    .where((task) => isSameDay(task.date, day))
                    .toList();
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AllTasksPage extends StatelessWidget {
  // Added All Tasks Page
  final List<Task> tasks;
  final Map<String, int> categoryCounts;
  final Function(Task) onDeleteTask;
  final Function(Task) onToggleTask;

  const AllTasksPage({
    super.key,
    required this.tasks,
    required this.categoryCounts,
    required this.onDeleteTask,
    required this.onToggleTask,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Tasks',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CategoryChip(
                  icon: Icons.favorite,
                  label: 'Health',
                  count: categoryCounts['Health'] ?? 0,
                  color: Colors.blue,
                ),
                _CategoryChip(
                  icon: Icons.work,
                  label: 'Work',
                  count: categoryCounts['Work'] ?? 0,
                  color: Colors.green,
                ),
                _CategoryChip(
                  icon: Icons.psychology,
                  label: 'Mental Health',
                  count: categoryCounts['Mental Health'] ?? 0,
                  color: Colors.purple,
                ),
                _CategoryChip(
                  icon: Icons.more_horiz,
                  label: 'Others',
                  count: categoryCounts['Others'] ?? 0,
                  color: Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Text(
                        'No tasks available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Dismissible(
                          key: Key(task.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => onDeleteTask(task),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: _TaskItem(
                            task: task,
                            onToggle: () => onToggleTask(task),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class NewTaskSheet extends StatefulWidget {
  final Function(String title, String category, DateTime date) onAddTask;

  const NewTaskSheet({
    super.key,
    required this.onAddTask,
  });

  @override
  State<NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends State<NewTaskSheet> {
  final TextEditingController _titleController = TextEditingController();
  String _category = 'Health';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Show date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Show time picker
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _submit() {
    final title = _titleController.text;
    if (title.isEmpty) {
      return;
    }

    // Combine date and time to create a full DateTime
    final DateTime fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    widget.onAddTask(title, _category, fullDateTime);
    Navigator.pop(context);
  }

  void _cancel() {
    Navigator.pop(context); // Close the sheet without doing anything
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        width: MediaQuery.of(context).size.width *
            0.75, // Adjusted width to make it smaller
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize
              .min, // Ensures the column doesn't take up excess space
          children: [
            const Text(
              'Add Task',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButton<String>(
              value: _category,
              onChanged: (value) {
                setState(() {
                  _category = value!;
                });
              },
              items: const [
                DropdownMenuItem(
                  value: 'Health',
                  child: Text('Health'),
                ),
                DropdownMenuItem(
                  value: 'Work',
                  child: Text('Work'),
                ),
                DropdownMenuItem(
                  value: 'Mental Health',
                  child: Text('Mental Health'),
                ),
                DropdownMenuItem(
                  value: 'Others',
                  child: Text('Others'),
                ),
              ],
              isExpanded: true,
              underline: SizedBox(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "Time: ${_selectedTime.format(context)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // To space the buttons apart
              children: [
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add Task',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: _cancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                        255, 242, 221, 245), // Corrected parameter name
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
