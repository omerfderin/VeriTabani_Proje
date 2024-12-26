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
    _taskStatusTimer = Timer.periodic(const Duration(days: 1), (Timer t) => _checkTaskStatus());
  }

  @override
  void dispose() {
    _taskStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    try {
      final response = await http.get(
          Uri.parse('http://localhost:3000/tasks/${widget.selectedProject.pID}')
      );

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
              Theme.of(context).primaryColor.withOpacity(0.1)
          ),
          columns: [
            DataColumn(label: Text('Başlangıç Tarihi',
                style: Theme.of(context).textTheme.titleMedium)),
            DataColumn(label: Text('Adam Gün Değeri',
                style: Theme.of(context).textTheme.titleMedium)),
            DataColumn(label: Text('Bitiş Tarihi',
                style: Theme.of(context).textTheme.titleMedium)),
            DataColumn(label: Text('Durum',
                style: Theme.of(context).textTheme.titleMedium)),
            DataColumn(label: Text('Çalışan',
                style: Theme.of(context).textTheme.titleMedium)),
            DataColumn(label: Text('Gecikme Süresi (Gün)',
                style: Theme.of(context).textTheme.titleMedium)),
            DataColumn(label: Text('Aksiyonlar',
                style: Theme.of(context).textTheme.titleMedium)),
          ],
          rows: _tasksFromApi.map<DataRow>((task) {
            final endDate = DateTime.parse(task['gBitisTarih']);
            final delay = now.isAfter(endDate) ? now.difference(endDate).inDays : 0;

            return DataRow(
              color: MaterialStateProperty.all(
                  delay > 0 ? Theme.of(context).colorScheme.error.withOpacity(0.1) : null
              ),
              cells: [
                DataCell(Text(_formatDate(task['gBaslaTarih']),
                    style: Theme.of(context).textTheme.bodyMedium)),
                DataCell(Text(task['gAdamGun'].toString(),
                    style: Theme.of(context).textTheme.bodyMedium)),
                DataCell(Text(_formatDate(task['gBitisTarih']),
                    style: Theme.of(context).textTheme.bodyMedium)),
                DataCell(Text(task['gDurum'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(task['gDurum'])
                    ))),
                DataCell(
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeProfilePage(
                            employeeId: task['Calisanlar_cID'] ?? task['cID'] ?? 0,
                            employeeName: task['cAdSoyad'] ?? 'Bilinmeyen',
                          ),
                        ),
                      );
                    },
                    child: Text(
                      task['cAdSoyad'] ?? 'Atanmamış',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                DataCell(Text(delay > 0 ? delay.toString() : '-',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: delay > 0 ? Theme.of(context).colorScheme.error : null
                    ))),
                DataCell(
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert,
                        color: Theme.of(context).colorScheme.secondary),
                    onSelected: (String action) async {
                      if (action == 'edit') {
                        _showEditTaskDialog(task);
                      } else if (action == 'delete') {
                        await _deleteTask(task['gID']);
                        _fetchTasks();
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Düzenle',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Sil',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error
                            )),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Tamamlandı':
        return Colors.green;
      case 'Devam Ediyor':
        return Colors.orange;
      case 'Gecikmiş':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    }
  }

  Future<void> _showEditTaskDialog(Map<String, dynamic> task) async {
    String? _selectedStatus = task['gDurum'];
    final List<String> _validStatuses = ['Tamamlanacak', 'Devam Ediyor', 'Tamamlandı'];

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
                child: Text(status,
                    style: Theme.of(context).textTheme.bodyMedium),
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
                          style: TextStyle(color: Theme.of(context).colorScheme.onError)),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }

                try {
                  final response = await http.put(
                    Uri.parse('http://localhost:3000/tasks/${task['gID']}/status'),
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
                          style: TextStyle(color: Theme.of(context).colorScheme.onError)),
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
      // Silme işlemi için onay dialogu göster
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

    for (var task in _tasksFromApi) {
      try {
        final endDate = DateTime.parse(task['gBitisTarih']);

        // Görev tamamlanmamışsa ve gecikmişse işlem yap
        if (endDate.isBefore(now) && task['gDurum'] != 'Tamamlandı') {
          final delayDays = now.difference(endDate).inDays;

          // Görev durumunu güncelle
          final taskUpdateResponse = await http.put(
            Uri.parse('http://localhost:3000/tasks/${task['gID']}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'gDurum': 'Gecikmiş',
              'gecikmeGun': delayDays,
            }),
          );

          if (taskUpdateResponse.statusCode != 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Görev durumu güncellenemedi',
                  style: TextStyle(color: Theme.of(context).colorScheme.onError),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
            continue;
          }

          // Projenin bitiş tarihini güncelle
          final newEndDate = widget.selectedProject.pBitisTarih.add(Duration(days: delayDays));
          final projectUpdateResponse = await http.put(
            Uri.parse('http://localhost:3000/projects/${widget.selectedProject.pID}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'pBitisTarih': newEndDate.toIso8601String()}),
          );

          if (projectUpdateResponse.statusCode != 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Proje bitiş tarihi güncellenemedi',
                  style: TextStyle(color: Theme.of(context).colorScheme.onError),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } catch (e) {
        print('Hata oluştu: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Görev kontrolü sırasında hata: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    // Görev listesini güncelle
    await _fetchTasks();
  }

  String _formatDate(String date) {
    try {
      if (date.isEmpty) return 'Belirtilmemiş';

      DateTime parsedDate = DateTime.parse(date);
      return "${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}";
    } catch (e) {
      print('Date parsing error for value $date: $e');
      return 'Geçersiz Tarih';
    }
  }

// Yardımcı metot: Proje bitiş tarihini güncelle
  Future<void> _updateProjectEndDate(int delayDays) async {
    try {
      final response = await http.put(
        Uri.parse('http://localhost:3000/projects/${widget.selectedProject.pID}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'pBitisTarih': widget.selectedProject.pBitisTarih
              .add(Duration(days: delayDays))
              .toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Proje bitiş tarihi güncellenemedi');
      }
    } catch (e) {
      print('Error updating project end date: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Proje bitiş tarihi güncellenirken hata oluştu: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showAddTaskDialog() async {
    final _startDateController = TextEditingController();
    final _adamGunController = TextEditingController();
    final _endDateController = TextEditingController();
    String? _selectedEmployee;
    List<Map<String, dynamic>> _employees = [];

    try {
      final response = await http.get(Uri.parse('http://localhost:3000/employees'));
      if (response.statusCode == 200) {
        _employees = List<Map<String, dynamic>>.from(json.decode(response.body));
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
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: Theme.of(context).primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          _startDateController.text = date.toIso8601String().split('T')[0];
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
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context).colorScheme.copyWith(
                                  primary: Theme.of(context).primaryColor,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          _endDateController.text = date.toIso8601String().split('T')[0];
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Çalışan Seçin",
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
                              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
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
                              style: TextStyle(color: Theme.of(context).colorScheme.onError)),
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
          '${widget.selectedProject.pAd} Görevler',
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