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
    final completedTasks = _employeeTasks.where((task) => task['gDurum'] == 'Tamamlandı').toList();
    final ongoingTasks = _employeeTasks.where((task) {
      final startDate = DateTime.parse(task['gBaslaTarih']);
      final endDate = DateTime.parse(task['gBitisTarih']);
      return task['gDurum'] != 'Tamamlandı' &&
          startDate.isBefore(now) &&
          endDate.isAfter(now);
    }).toList();

    final upcomingTasks = _employeeTasks.where((task) {
      final startDate = DateTime.parse(task['gBaslaTarih']);
      return task['gDurum'] != 'Tamamlandı' &&
          startDate.isAfter(now);
    }).toList();

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Tamamlanan'),
              Tab(text: 'Devam Eden'),
              Tab(text: 'Gelecek'),
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
    final parsedDate = DateTime.parse(date);
    return '${parsedDate.day}.${parsedDate.month}.${parsedDate.year}';
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