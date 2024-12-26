import 'package:flutter/material.dart';
import 'employee_profile.dart';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeesPage extends StatefulWidget {
  final dynamic currentUser;

  const EmployeesPage({Key? key, required this.currentUser}) : super(key: key);

  @override
  _EmployeesPageState createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  List<Calisanlar> _employees = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/employees'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _employees = data.map((json) => Calisanlar.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Veri yüklenirken bir hata oluştu: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Veri yüklenirken bir hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteEmployee(Calisanlar employee) async {
    try {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/employees/${employee.cID}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çalışan başarıyla silindi')),
        );
        _fetchEmployees(); // Refresh the list
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorData['details'] ?? 'Bir hata oluştu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  Future<void> _updateEmployee(Calisanlar employee) async {
    final TextEditingController nameController = TextEditingController(
      text: employee.cAdSoyad,
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çalışan Güncelle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Ad Soyad',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final response = await http.put(
                  Uri.parse('http://localhost:3000/employees/${employee.cID}'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode({'cAdSoyad': nameController.text}),
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Çalışan güncellendi')),
                  );
                  _fetchEmployees(); // Refresh the list
                } else {
                  final errorData = json.decode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorData['details'] ?? 'Bir hata oluştu')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  Future<void> _addEmployee() async {
    final TextEditingController nameController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Çalışan Ekle'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Ad Soyad',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final newEmployee = {
                  'cAdSoyad': nameController.text,
                };

                final response = await http.post(
                  Uri.parse('http://localhost:3000/employees'),
                  headers: {'Content-Type': 'application/json'},
                  body: json.encode(newEmployee),
                );

                if (response.statusCode == 201) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Yeni çalışan başarıyla eklendi')),
                  );
                  _fetchEmployees(); // Refresh the list
                } else {
                  final errorData = json.decode(response.body);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorData['error'] ?? 'Bir hata oluştu')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Hata: $e')),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_employees.isEmpty) {
      return const Center(child: Text('Çalışan bulunamadı'));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _addEmployee,
                child: const Text('Yeni Çalışan Ekle'),
              ),
              DataTable(
                columns: const [
                  DataColumn(
                    label: Text(
                      'ID',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Ad Soyad',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'İşlemler',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                rows: _employees.map((employee) {
                  return DataRow(
                    cells: [
                      DataCell(Text(employee.cID.toString())),
                      DataCell(
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmployeeProfilePage(
                                  employeeId: employee.cID,
                                  employeeName: employee.cAdSoyad,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            employee.cAdSoyad,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _updateEmployee(employee),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Çalışan Sil'),
                                    content: Text('${employee.cAdSoyad} silinecek. Emin misiniz?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _deleteEmployee(employee);
                                        },
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}