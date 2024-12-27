import 'package:flutter/material.dart';
import 'package:vtys_proje/pages/employees.dart';
import 'models.dart';
import 'project_task_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectDetailsPage extends StatefulWidget {
  final List<Proje> projects;
  final Kullanici currentUser;
  final ThemeMode? initialThemeMode;

  const ProjectDetailsPage({
    Key? key,
    required this.projects,
    required this.currentUser,
    this.initialThemeMode,
  }) : super(key: key);

  @override
  _ProjectDetailsPageState createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = false;
  List<Map<String, dynamic>> _projectsFromApi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await http.get(
          Uri.parse('http://localhost:3000/projects'));
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          _projectsFromApi = List<Map<String, dynamic>>.from(decodedData);
          _isLoading = false;
        });
      } else {
        print('Error status code: ${response.statusCode}');
        throw Exception('Failed to load projects');
      }
    } catch (e) {
      print('Error fetching projects: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDataTable() {
    if (_isLoading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (_projectsFromApi.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            'Proje bulunamadı',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Expanded(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.95,
          ),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 40,
                        horizontalMargin: 20,
                        headingRowHeight: 60,
                        columns: [
                          DataColumn(
                            label: Container(
                              width: 150,
                              child: Text('Proje Adı',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 150,
                              child: Text('Başlangıç Tarihi',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 150,
                              child: Text('Bitiş Tarihi',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ),
                          DataColumn(
                            label: Container(
                              width: 180,
                              child: Text('Gecikme Süresi (Gün)',
                                  style: Theme.of(context).textTheme.titleMedium),
                            ),
                          ),
                        ],
                        rows: _projectsFromApi.map<DataRow>((project) {
                          int totalDelay = int.parse(project['totalDelay'].toString());
                          DateTime originalEndDate = DateTime.parse(project['originalEndDate'] ?? project['pBitisTarih']);
                          DateTime adjustedEndDate = DateTime.parse(project['pBitisTarih']).add(Duration(days: 1));

                          return DataRow(
                            cells: [
                              DataCell(
                                Container(
                                  width: 150,
                                  child: Text(
                                    project['pAd']?.toString() ?? 'Belirtilmemiş',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Colors.blue,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectTasksPage(
                                        selectedProject: Proje(
                                          kullanici: widget.currentUser,
                                          pID: project['pID'] ?? 0,
                                          pAd: project['pAd'],
                                          pBaslaTarih: DateTime.parse(project['pBaslaTarih']),
                                          pBitisTarih: adjustedEndDate,
                                        ),
                                        currentUser: widget.currentUser,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              DataCell(
                                Container(
                                  width: 150,
                                  child: Text(
                                    _formatAPIDate(project['pBaslaTarih']),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 150,
                                  child: Tooltip(
                                    message: 'Orijinal Bitiş Tarihi: ${_formatAPIDate(originalEndDate.toIso8601String())}',
                                    child: Text(
                                      _formatAPIDate(adjustedEndDate.toIso8601String()),
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: totalDelay > 0 ? Theme.of(context).colorScheme.error : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Container(
                                  width: 180,
                                  child: Text(
                                    totalDelay.toString(),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: totalDelay > 0 ? Theme.of(context).colorScheme.error : null,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatAPIDate(dynamic date) {
    if (date == null) return 'Belirtilmemiş';
    try {
      if (date is String) {
        final DateTime parsedDate = DateTime.parse(date).toLocal();
        final DateTime localDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
        return '${localDate.day.toString().padLeft(2, '0')}.${localDate.month.toString().padLeft(2, '0')}.${localDate.year}';
      }
      return date.toString();
    } catch (e) {
      print('Date parsing error for value $date: $e');
      return 'Belirtilmemiş';
    }
  }

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Projeler';
      case 1:
        return 'Çalışanlar';
      case 2:
        return 'Ayarlar';
      default:
        return 'Projeler';
    }
  }

  Widget _buildContent(int index) {
    switch (index) {
      case 0:
        return Column(
          children: [
            _buildDataTable(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _showAddProjectDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text("Yeni proje ekle",
                  style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                ),
              ),
            ),
          ],
        );
      case 1:
        return EmployeesPage(currentUser: widget.currentUser);
      case 2:
        return Center(
          child: Text(
            'Ayarlar',
            style: Theme
                .of(context)
                .textTheme
                .bodyLarge,
          ),
        );
      default:
        return Scaffold();
    }
  }

  void _showAddProjectDialog() async {
    final _projectNameController = TextEditingController();
    final _startDateController = TextEditingController();
    final _endDateController = TextEditingController();

    final result = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(
            "Yeni Proje Ekle",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _projectNameController,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: "Proje Adı",
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
              ),
              SizedBox(height: 16),
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
                    firstDate: DateTime.now(),
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
                    final selectedDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
                    _startDateController.text = selectedDate.toIso8601String().split('T')[0];
                  }
                },
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
                    firstDate: DateTime.now(),
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
                    final selectedDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
                    _endDateController.text = selectedDate.toIso8601String().split('T')[0];
                  }
                },
              ),
            ],
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
              onPressed: () {
                if (_projectNameController.text.isEmpty ||
                    _startDateController.text.isEmpty ||
                    _endDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Lütfen tüm alanları doldurun"),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
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

    if (result == true) {
      try {
        final requestData = {
          'pAd': _projectNameController.text,
          'pBaslaTarih': _startDateController.text,
          'pBitisTarih': _endDateController.text,
          'Kullanici_kID': widget.currentUser.kID,
        };

        final response = await http.post(
          Uri.parse('http://localhost:3000/projects'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestData),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Proje başarıyla eklendi"),
            ),
          );
          _fetchProjects();
        } else {
          final errorResponse = json.decode(response.body);
          String errorMessage = 'Hata: ';
          if (errorResponse['details'] is Map) {
            errorResponse['details'].forEach((key, value) {
              if (value != null) {
                errorMessage += '$value, ';
              }
            });
          } else {
            errorMessage += errorResponse['error'] ?? 'Bilinmeyen bir hata oluştu';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bağlantı hatası: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .surface,
          elevation: 1,
          centerTitle: true,
          title: Text(
            _getPageTitle(),
            style: Theme
                .of(context)
                .textTheme
                .titleLarge,
          ),
          leading: IconButton(
            iconSize: 30,
            icon: Icon(
              Icons.menu,
              color: Theme
                  .of(context)
                  .colorScheme
                  .secondary,
            ),
            onPressed: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme
                  .of(context)
                  .primaryColor
                  .withOpacity(0.1),
              Theme
                  .of(context)
                  .colorScheme
                  .secondary
                  .withOpacity(0.1),
            ],
          ),
        ),
        child: Row(
          children: [
            if (_isSidebarOpen)
              NavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _isSidebarOpen = false;
                  });
                },
                labelType: NavigationRailLabelType.all,
                backgroundColor: Theme
                    .of(context)
                    .colorScheme
                    .surface,
                selectedIconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                unselectedIconTheme: IconThemeData(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .secondary,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.work),
                    label: Text('Projeler'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people),
                    label: Text('Çalışanlar'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Ayarlar'),
                  ),
                ],
              ),
            Expanded(
              child: _buildContent(_selectedIndex),
            ),
          ],
        ),
      ),
    );
  }
}