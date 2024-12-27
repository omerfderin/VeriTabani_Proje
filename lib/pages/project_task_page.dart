import 'package:flutter/material.dart';
import 'models.dart';
import 'Employee_profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ProjectTasksPage extends StatefulWidget {
  final Proje selectedProject;
  final Kullanici currentUser;

  const ProjectTasksPage({
    Key? key,
    required this.selectedProject,
    required this.currentUser,
  }) : super(key: key);

  @override
  _ProjectTasksPageState createState() => _ProjectTasksPageState();
}

class _ProjectTasksPageState extends State<ProjectTasksPage> {
  List<Map<String, dynamic>> _tasksFromApi = [];
  bool _isLoading = true;
  Timer? _taskStatusTimer;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _taskStatusTimer = Timer.periodic(
        const Duration(days: 1), (Timer t) => _checkTaskStatus());
  }

  @override
  void dispose() {
    _taskStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost:3000/tasks/${widget.selectedProject.pID}'));

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          _tasksFromApi = List<Map<String, dynamic>>.from(decodedData);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print('Error fetching tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTaskTable() {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (_tasksFromApi.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'Görev bulunamadı',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final now = DateTime.now();

    return Expanded(
        child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 16,
                  ),
                  child: DataTable(
                    columnSpacing: 20,
                    horizontalMargin: 10,
                    headingRowColor: MaterialStateProperty.all(
                        Theme.of(context).primaryColor.withOpacity(0.1)),
                    columns: [
                      DataColumn(
                          label: Text('Başlangıç Tarihi',
                              style: Theme.of(context).textTheme.titleMedium)),
                      DataColumn(
                          label: Text('Adam Gün Değeri',
                              style: Theme.of(context).textTheme.titleMedium)),
                      DataColumn(
                          label: Text('Bitiş Tarihi',
                              style: Theme.of(context).textTheme.titleMedium)),
                      DataColumn(
                          label: Text('Durum',
                              style: Theme.of(context).textTheme.titleMedium)),
                      DataColumn(
                          label: Text('Çalışan',
                              style: Theme.of(context).textTheme.titleMedium)),
                      DataColumn(
                          label: Text('Gecikme Süresi (Gün)',
                              style: Theme.of(context).textTheme.titleMedium)),
                      DataColumn(
                          label: Text('Aksiyonlar',
                              style: Theme.of(context).textTheme.titleMedium)),
                    ],
                    rows: _tasksFromApi.map<DataRow>((task) {
                      final endDate = DateTime.parse(task['gBitisTarih']);
                      final delay = now.isAfter(endDate)
                          ? now.difference(endDate).inDays
                          : 0;

                      return DataRow(
                        color: MaterialStateProperty.all(delay > 0
                            ? Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.1)
                            : null),
                        cells: [
                          DataCell(Text(_formatDate(task['gBaslaTarih']),
                              style: Theme.of(context).textTheme.bodyMedium)),
                          DataCell(Text(task['gAdamGun'].toString(),
                              style: Theme.of(context).textTheme.bodyMedium)),
                          DataCell(Text(_formatDate(task['gBitisTarih']),
                              style: Theme.of(context).textTheme.bodyMedium)),
                          DataCell(Text(task['gDurum'] ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: _getStatusColor(task['gDurum'])))),
                          DataCell(
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EmployeeProfilePage(
                                      employeeId: task['Calisanlar_cID'] ??
                                          task['cID'] ??
                                          0,
                                      employeeName:
                                          task['cAdSoyad'] ?? 'Bilinmeyen',
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                task['cAdSoyad'] ?? 'Atanmamış',
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          DataCell(Text(delay > 0 ? delay.toString() : '-',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: delay > 0
                                          ? Theme.of(context).colorScheme.error
                                          : null))),
                          DataCell(
                            PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert,
                                  color:
                                      Theme.of(context).colorScheme.secondary),
                              onSelected: (String action) async {
                                if (action == 'edit') {
                                  _showEditTaskDialog(task);
                                } else if (action == 'delete') {
                                  await _deleteTask(task['gID']);
                                }
                              },
                              itemBuilder: (BuildContext context) =>
                                  <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Text('Düzenle',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Text('Sil',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            )));
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Tamamlandı':
        return Colors.green;
      case 'Devam Ediyor':
        return Colors.orange;
      case 'Tamamlanacak':
        return Colors.blue;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    }
  }

  Future<void> _showEditTaskDialog(Map<String, dynamic> task) async {
    String? _selectedStatus = task['gDurum'];
    final List<String> _validStatuses = [
      'Tamamlanacak',
      'Devam Ediyor',
      'Tamamlandı'
    ];

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text("Görev Durumunu Güncelle",
              style: Theme.of(context).textTheme.titleLarge),
          content: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Durum Seçin",
              labelStyle: Theme.of(context).textTheme.bodyMedium,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor),
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            value: _selectedStatus,
            dropdownColor: Theme.of(context).colorScheme.surface,
            items: _validStatuses.map((status) {
              return DropdownMenuItem(
                value: status,
                child:
                    Text(status, style: Theme.of(context).textTheme.bodyMedium),
              );
            }).toList(),
            onChanged: (value) {
              _selectedStatus = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedStatus == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Lütfen bir durum seçin",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onError)),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                try {
                  final response = await http.put(
                    Uri.parse(
                        'http://localhost:3000/tasks/${task['gID']}/status'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'gDurum': _selectedStatus}),
                  );

                  if (response.statusCode == 200) {
                    Navigator.pop(context, true);
                  } else {
                    throw Exception('Durum güncellenemedi: ${response.body}');
                  }
                } catch (e) {
                  print('Error updating task status: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Durum güncellenirken bir hata oluştu: $e",
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onError)),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text("Güncelle"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _fetchTasks();
    }
  }

  Future<void> _deleteTask(int taskId) async {
    try {
      final bool? confirmDelete = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            'Görevi Sil',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            'Bu görevi silmek istediğinizden emin misiniz?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: Text('Sil'),
            ),
          ],
        ),
      );

      if (confirmDelete != true) return;

      final response = await http.delete(
        Uri.parse('http://localhost:3000/tasks/$taskId'),
      );

      if (response.statusCode == 200) {
        await _fetchTasks();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görev başarıyla silindi',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      } else {
        throw Exception('Görev silinemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hata: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _checkTaskStatus() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var task in _tasksFromApi) {
      try {
        final startDate = DateTime.parse(task['gBaslaTarih']).toLocal();
        final taskStartDate = DateTime(startDate.year, startDate.month, startDate.day);

        String newStatus;
        if (task['gDurum'] == 'Tamamlandı') {
          continue;
        } else if (taskStartDate.isAfter(today)) {
          newStatus = 'Tamamlanacak';
        } else {
          newStatus = 'Devam Ediyor';
        }

        if (task['gDurum'] != newStatus) {
          final response = await http.put(
            Uri.parse('http://localhost:3000/tasks/${task['gID']}/status'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'gDurum': newStatus}),
          );

          if (response.statusCode != 200) {
            throw Exception('Görev durumu güncellenemedi');
          }
        }
      } catch (e) {
        print('Görev kontrolü sırasında hata: $e');
      }
    }

    await _fetchTasks();
  }

  String _formatDate(String date) {
    try {
      if (date.isEmpty) return 'Belirtilmemiş';
      DateTime parsedDate = DateTime.parse(date).toLocal();
      parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      return "${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}";
    } catch (e) {
      print('Date parsing error for value $date: $e');
      return 'Geçersiz Tarih';
    }
  }



  void _showAddTaskDialog() async {
    final _startDateController = TextEditingController();
    final _adamGunController = TextEditingController();
    final _endDateController = TextEditingController();
    String? _selectedEmployee;
    List<Map<String, dynamic>> _employees = [];

    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/employees'));
      if (response.statusCode == 200) {
        _employees =
            List<Map<String, dynamic>>.from(json.decode(response.body));
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }

    final result = await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text("Yeni Görev Ekle",
                  style: Theme.of(context).textTheme.titleLarge),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _startDateController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: "Başlangıç Tarihi (YYYY-MM-DD)",
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context)
                                    .colorScheme
                                    .copyWith(
                                      primary: Theme.of(context).primaryColor,
                                    ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          // Sadece tarih bilgisini al, saat bilgisini sıfırla
                          final selectedDate =
                              DateTime(date.year, date.month, date.day);
                          _startDateController.text =
                              selectedDate.toIso8601String().split('T')[0];
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _adamGunController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: "Adam Gün Değeri",
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _endDateController,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        labelText: "Bitiş Tarihi (YYYY-MM-DD)",
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context)
                                    .colorScheme
                                    .copyWith(
                                      primary: Theme.of(context).primaryColor,
                                    ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          final selectedDate =
                              DateTime(date.year, date.month, date.day);
                          _endDateController.text =
                              selectedDate.toIso8601String().split('T')[0];
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Çalışan Seçin",
                        labelStyle: Theme.of(context).textTheme.bodyMedium,
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      value: _selectedEmployee,
                      items: _employees.map((employee) {
                        return DropdownMenuItem(
                          value: employee['cID'].toString(),
                          child: Text(
                            employee['cAdSoyad'] ?? 'İsimsiz Çalışan',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedEmployee = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  child: Text("İptal"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_startDateController.text.isEmpty ||
                        _endDateController.text.isEmpty ||
                        _adamGunController.text.isEmpty ||
                        _selectedEmployee == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lütfen tüm alanları doldurun",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onError)),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                      return;
                    }

                    try {
                      final requestBody = {
                        'gBaslaTarih': _startDateController.text,
                        'gBitisTarih': _endDateController.text,
                        'gAdamGun': int.parse(_adamGunController.text),
                        'gDurum': 'Tamamlanacak',
                        'Calisanlar_cID': int.parse(_selectedEmployee!),
                        'Proje_pID': widget.selectedProject.pID,
                      };

                      final response = await http.post(
                        Uri.parse('http://localhost:3000/tasks'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode(requestBody),
                      );

                      if (response.statusCode == 201) {
                        Navigator.pop(context, true);
                      } else {
                        throw Exception('Failed to add task: ${response.body}');
                      }
                    } catch (e) {
                      print('Error adding task: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Görev eklenirken bir hata oluştu: $e",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onError)),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _fetchTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          '${widget.selectedProject.pAd} Görevleri',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.secondary,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddTaskDialog,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildTaskTable(),
          ],
        ),
      ),
    );
  }
}
