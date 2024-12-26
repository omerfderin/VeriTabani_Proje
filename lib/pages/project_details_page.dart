import 'package:flutter/material.dart';
import 'package:vtys_proje/pages/employees.dart';
import 'models.dart';
import 'project_task_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectDetailsPage extends StatefulWidget {
  final List<Proje> projects;
  final Kullanici currentUser;
  final String? initialLanguage;
  final ThemeMode? initialThemeMode;

  const ProjectDetailsPage({
    Key? key,
    required this.projects,
    required this.currentUser,
    this.initialLanguage,
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
      final response = await http.get(Uri.parse('http://localhost:3000/projects'));
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
      return Center(child: CircularProgressIndicator(
        color: Theme.of(context).primaryColor,
      ));
    }

    if (_projectsFromApi.isEmpty) {
      return Center(child: Text(
        'Proje bulunamadı',
        style: Theme.of(context).textTheme.bodyMedium,
      ));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: [
              DataColumn(label: Text('Proje Adı',
                  style: Theme.of(context).textTheme.titleMedium)),
              DataColumn(label: Text('Başlangıç Tarihi',
                  style: Theme.of(context).textTheme.titleMedium)),
              DataColumn(label: Text('Bitiş Tarihi',
                  style: Theme.of(context).textTheme.titleMedium)),
            ],
            rows: _projectsFromApi.map<DataRow>((project) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                        project['pAd']?.toString() ?? 'Belirtilmemiş',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: Theme.of(context).primaryColor,
                        )
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
                              pBitisTarih: DateTime.parse(project['pBitisTarih']),
                            ),
                            currentUser: widget.currentUser,
                          ),
                        ),
                      );
                    },
                  ),
                  DataCell(Text(_formatAPIDate(project['pBaslaTarih']),
                      style: Theme.of(context).textTheme.bodyMedium)),
                  DataCell(Text(_formatAPIDate(project['pBitisTarih']),
                      style: Theme.of(context).textTheme.bodyMedium)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatAPIDate(dynamic date) {
    if (date == null) return 'Belirtilmemiş';
    try {
      if (date is String) {
        final DateTime parsedDate = DateTime.parse(date);
        return '${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}';
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
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildDataTable(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showAddProjectDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Yeni proje ekle"),
              ),
            ],
          ),
        );
      case 1:
        return EmployeesPage(currentUser: widget.currentUser);
      case 2:
        return Center(
          child: Text(
            'Ayarlar',
            style: Theme.of(context).textTheme.bodyLarge,
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
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _startDateController.text = date.toIso8601String().split('T')[0];
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
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _endDateController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (_projectNameController.text.isEmpty ||
                    _startDateController.text.isEmpty ||
                    _endDateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Ekle"),
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
              backgroundColor: Theme.of(context).primaryColor,
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
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bağlantı hatası: $e"),
            backgroundColor: Colors.red,
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 1,
          centerTitle: true,
          title: Text(
            _getPageTitle(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          leading: IconButton(
            iconSize: 30,
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).colorScheme.secondary,
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
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Row(
          children: [
            if (_isSidebarOpen)
              NavigationSidebar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                    _isSidebarOpen = false;
                  });
                },
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

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const NavigationSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 225,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            selected: selectedIndex == 0,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            leading: Icon(
              Icons.work,
              color: selectedIndex == 0
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Projeler',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selectedIndex == 0
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            onTap: () => onItemSelected(0),
          ),
          ListTile(
            selected: selectedIndex == 1,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            leading: Icon(
              Icons.people,
              color: selectedIndex == 1
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Çalışanlar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selectedIndex == 1
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            onTap: () => onItemSelected(1),
          ),
          ListTile(
            selected: selectedIndex == 2,
            selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
            leading: Icon(
              Icons.settings,
              color: selectedIndex == 2
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).colorScheme.secondary,
            ),
            title: Text(
              'Ayarlar',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selectedIndex == 2
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            onTap: () => onItemSelected(2),
          ),
        ],
      ),
    );
  }
}