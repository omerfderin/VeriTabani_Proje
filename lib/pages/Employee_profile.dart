import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EmployeeProfilePage extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const EmployeeProfilePage({
    Key? key,
    required this.employeeId,
    required this.employeeName,
  }) : super(key: key);

  @override
  EmployeeProfilePageState createState() => EmployeeProfilePageState();
}

class EmployeeProfilePageState extends State<EmployeeProfilePage> {
  List<Map<String, dynamic>> _employeeTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeTasks();
  }

  Future<void> _fetchEmployeeTasks() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/tasks/employee/${widget.employeeId}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _employeeTasks = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Çalışan görevleri yüklenemedi.');
      }
    } catch (e) {
      print('Error fetching employee tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTaskList() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final completedTasks = _employeeTasks.where((task) =>
    task['gDurum'] == 'Tamamlandı'
    ).toList();

    final ongoingTasks = _employeeTasks.where((task) {
      final startDate = DateTime.parse(task['gBaslaTarih']).toLocal();
      final endDate = DateTime.parse(task['gBitisTarih']).toLocal();
      final taskStartDate = DateTime(startDate.year, startDate.month, startDate.day);
      final taskEndDate = DateTime(endDate.year, endDate.month, endDate.day);

      return task['gDurum'] != 'Tamamlandı' &&
          !taskStartDate.isAfter(today) &&
          !taskEndDate.isBefore(today);
    }).toList();

    final upcomingTasks = _employeeTasks.where((task) {
      final startDate = DateTime.parse(task['gBaslaTarih']).toLocal();
      final taskStartDate = DateTime(startDate.year, startDate.month, startDate.day);

      return task['gDurum'] != 'Tamamlandı' &&
          taskStartDate.isAfter(today);
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Tamamlanan'),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${completedTasks.length}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.headlineLarge?.color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Devam Eden'),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${ongoingTasks.length}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.headlineLarge?.color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Gelecek'),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${upcomingTasks.length}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.headlineLarge?.color,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTaskListView(completedTasks),
                _buildTaskListView(ongoingTasks),
                _buildTaskListView(upcomingTasks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListView(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('Bu kategoride görev bulunmamaktadır.'),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          child: ListTile(
            title: Text('Proje: ${task['projeAdi'] ?? 'Bilinmeyen Proje'}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Başlangıç: ${_formatDate(task['gBaslaTarih'] ?? '')}'),
                Text('Bitiş: ${_formatDate(task['gBitisTarih'] ?? '')}'),
                Text('Durum: ${task['gDurum'] ?? 'Belirtilmemiş'}'),
                if (task['gAdamGun'] != null) Text('Adam Gün: ${task['gAdamGun']}'),
                if (task['gecikmeGun'] != null && task['gecikmeGun'] > 0)
                  Text(
                    'Gecikme: ${task['gecikmeGun']} gün',
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String date) {
    try {
      if (date.isEmpty) return 'Belirtilmemiş';

      // UTC'den yerel saat dilimine çevirme
      DateTime parsedDate = DateTime.parse(date).toLocal();
      // Saat bilgisini sıfırlayarak sadece tarih bilgisini al
      parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      return "${parsedDate.day.toString().padLeft(2, '0')}.${parsedDate.month.toString().padLeft(2, '0')}.${parsedDate.year}";
    } catch (e) {
      print('Date parsing error for value $date: $e');
      return 'Geçersiz Tarih';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.employeeName} Profili'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTaskList(),
    );
  }
}