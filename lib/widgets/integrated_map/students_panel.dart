import 'package:flutter/material.dart';

class StudentsPanel extends StatelessWidget {
  final bool isExpanded;
  final Map<String, dynamic>? nextStop;
  final List<dynamic> students;
  final VoidCallback onToggleExpanded;

  const StudentsPanel({
    super.key,
    required this.isExpanded,
    required this.nextStop,
    required this.students,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Students at Next Stop',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  if (nextStop != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_getStudentsAtStop(nextStop!['name']).length}',
                        style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _buildStudentsList(context),
            ),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getStudentsAtStop(String stopName) {
    return students
        .where((student) =>
            student['pickupLocation'] == stopName ||
            student['dropoffLocation'] == stopName)
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Widget _buildStudentsList(BuildContext context) {
    if (nextStop == null) {
      return const Center(child: Text('No stop information available'));
    }

    final studentsAtStop = _getStudentsAtStop(nextStop!['name']);

    if (studentsAtStop.isEmpty) {
      return const Center(child: Text('No students at this stop'));
    }

    return ListView.builder(
      itemCount: studentsAtStop.length,
      itemBuilder: (context, index) {
        final student = studentsAtStop[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                student['name']?.substring(0, 1).toUpperCase() ?? '?',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              student['name'] ?? 'Unknown Student',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (student['class'] != null)
                  Text('Class: ${student['class']}'),
                if (student['parentName'] != null)
                  Text('Parent: ${student['parentName']}'),
              ],
            ),
            trailing: student['parentPhone'] != null
                ? IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Call: ${student['parentPhone']}'),
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}