import 'package:flutter/material.dart';
import 'package:truelovesocio/model/category_model.dart';
import 'package:truelovesocio/service/api_service.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  final Map<String, TimeOfDay?> _startTimes = {};
  final Map<String, TimeOfDay?> _endTimes = {};
  final Map<String, bool> _activeDays = {};

  @override
  void initState() {
    super.initState();
    _initializeSchedules();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
    }
  }

  void _initializeSchedules() {
    for (var day in _daysOfWeek) {
      if (widget.category != null && widget.category!.horarios.isNotEmpty) {
        final existing = widget.category!.horarios.firstWhere(
          (element) => element.day == day,
          orElse: () => CategorySchedule(day: day, isActive: false),
        );
        _activeDays[day] = existing.isActive;
        if (existing.startTime != null && existing.startTime!.contains(':')) {
          final parts = existing.startTime!.split(':');
          _startTimes[day] = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
        if (existing.endTime != null && existing.endTime!.contains(':')) {
          final parts = existing.endTime!.split(':');
          _endTimes[day] = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } else {
        _activeDays[day] = true;
      }
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Hora';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<CategorySchedule> _buildSchedulesFromState() {
    List<CategorySchedule> schedules = [];
    for (var day in _daysOfWeek) {
      String? startStr;
      String? endStr;

      if (_startTimes[day] != null) {
        startStr = _formatTime(_startTimes[day]);
      }
      if (_endTimes[day] != null) {
        endStr = _formatTime(_endTimes[day]);
      }

      schedules.add(
        CategorySchedule(
          day: day,
          startTime: startStr,
          endTime: endStr,
          isActive: _activeDays[day] ?? true,
        ),
      );
    }
    return schedules;
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final schedules = _buildSchedulesFromState();

      if (widget.category == null) {
        // Create
        await _apiService.createCategory(
          _nameController.text,
          horarios: schedules,
        );
      } else {
        // Update
        await _apiService.updateCategory(
          widget.category!.id,
          _nameController.text,
          horarios: schedules,
        );
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Categoría' : 'Agregar Categoría'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre de la Categoría',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese un nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Horarios de Disponibilidad",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Configura los días y horas en que esta categoría estará disponible.",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ..._daysOfWeek.map((day) => _buildDayRow(day)),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveCategory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E88E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isEditing
                                ? 'Actualizar Categoría'
                                : 'Crear Categoría',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDayRow(String day) {
    final isActive = _activeDays[day] ?? true;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: isActive,
                  activeColor: const Color(0xFF1E88E5),
                  onChanged: (val) {
                    setState(() {
                      _activeDays[day] = val!;
                    });
                  },
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime:
                                _startTimes[day] ??
                                const TimeOfDay(hour: 8, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              _startTimes[day] = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _startTimes[day] != null
                                    ? _formatTime(_startTimes[day])
                                    : 'Inicio',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("-", style: TextStyle(color: Colors.grey)),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime:
                                _endTimes[day] ??
                                const TimeOfDay(hour: 20, minute: 0),
                          );
                          if (picked != null) {
                            setState(() {
                              _endTimes[day] = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _endTimes[day] != null
                                    ? _formatTime(_endTimes[day])
                                    : 'Fin',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
