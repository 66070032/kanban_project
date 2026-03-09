import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/card_decoration.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/task_provider.dart';
import '../widget/voice_recorder_widget.dart';

class TaskScreen extends ConsumerStatefulWidget {
  const TaskScreen({super.key});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedStatus = 'todo';
  String? _voicePath;
  bool _isSaving = false;
  String? _titleError;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _titleError = 'Title is required');
      return false;
    }
    setState(() => _titleError = null);
    return true;
  }

  Future<void> _handleSave() async {
    if (!_validate()) return;

    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to create tasks')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Build due_at ISO string if both date and time are selected
    String? dueAtIso;
    if (_dueDate != null) {
      final t = _dueTime ?? const TimeOfDay(hour: 23, minute: 59);
      final combined = DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        t.hour,
        t.minute,
      );
      dueAtIso = combined.toIso8601String();
    }

    final taskData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'status': _selectedStatus,
      'assignee_id': user.id,
      'due_at': dueAtIso,
      if (_voicePath != null) 'voiceInstructionPath': _voicePath,
    };

    final success = await ref.read(tasksProvider.notifier).createTask(taskData);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ref.invalidate(userTasksProvider(user.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create task. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Task',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan[400],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.cyan[400],
                    child: const Icon(
                      Icons.edit,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: CardDecorations.inputDecoration(),
                          child: TextField(
                            controller: _titleController,
                            onChanged: (_) {
                              if (_titleError != null) {
                                setState(() => _titleError = null);
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Task Title',
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_titleError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              _titleError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status picker
              const Text(
                'Status',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: CardDecorations.inputDecoration(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'todo', child: Text('To Do')),
                      DropdownMenuItem(
                        value: 'doing',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(value: 'done', child: Text('Done')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Due date / time picker
              const Text(
                'Due Date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: CardDecorations.inputDecoration(),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dueDate != null
                                  ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                  : 'Pick date',
                              style: TextStyle(
                                color: _dueDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime:
                              _dueTime ?? const TimeOfDay(hour: 23, minute: 59),
                        );
                        if (picked != null) setState(() => _dueTime = picked);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: CardDecorations.inputDecoration(),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_outlined,
                              size: 18,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dueTime != null
                                  ? _dueTime!.format(context)
                                  : 'Pick time',
                              style: TextStyle(
                                color: _dueTime != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_dueDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => setState(() {
                        _dueDate = null;
                        _dueTime = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Voice attachment
              const Text(
                'Audio Attachment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              VoiceRecorderWidget(
                title: 'Voice Description',
                accentColor: Colors.cyan[400]!,
                onRecordingComplete: (filePath, duration) {
                  setState(() => _voicePath = filePath);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Voice recorded: ${duration.inSeconds}s'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: CardDecorations.inputDecoration(),
                child: TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Add more details...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
