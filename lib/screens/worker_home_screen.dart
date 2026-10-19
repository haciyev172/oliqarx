import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/attendance_service.dart';
import 'qr_selfie_screen.dart';

class WorkerHomeScreen extends StatelessWidget {
  final User? user;
  final Map<String, dynamic> userData;

  const WorkerHomeScreen({
    super.key,
    this.user,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = userData['fullName'] ?? user?.displayName ?? "Elmir Məmmədov";
    final workerId = userData['worker_id'] ?? "OLQ-1042";
    final department = userData['department'] ?? "Mühafizə & Nəzarət";
    final dateStr = DateFormat('dd MMMM yyyy, EEEE', 'az').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Oliqarx Klub · İşçi Paneli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Hesabdan Çıxış',
            onPressed: () => _confirmSignOut(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : "E",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text("$workerId · $department", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(dateStr, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildActionButton(
              title: "Kluba Giriş",
              subtitle: "Qapı QR kodunu skan et və təsdiq selfie çək",
              icon: Icons.login,
              color: const Color(0xFF10B981),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrSelfieScreen(attendanceType: 'CHECK_IN')),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildActionButton(
              title: "Klubdan Çıxış",
              subtitle: "Növbəni tamamla və QR ilə qeydiyyatdan çıx",
              icon: Icons.logout,
              color: const Color(0xFFF97316),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QrSelfieScreen(attendanceType: 'CHECK_OUT')),
                );
              },
            ),
            const SizedBox(height: 26),
            const Text(
              "Son Giriş-Çıxış Hərəkətlərim",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder(
              stream: AttendanceService().streamWorkerRecentLogs(user?.uid ?? 'DEMO_1042'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Text("Hələlik aktiv giriş qeydi yoxdur.", textAlign: TextAlign.center),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: const Text("Hələlik aktiv giriş qeydi yoxdur.", textAlign: TextAlign.center),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final isCheckIn = data['type'] == 'CHECK_IN';
                    final time = data['created_at'] != null ? data['created_at'].toString().substring(11, 16) : "--:--";
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCheckIn ? Colors.green.shade50 : Colors.orange.shade50,
                          child: Icon(
                            isCheckIn ? Icons.login : Icons.logout,
                            color: isCheckIn ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(isCheckIn ? "Vardiya Girişi" : "Vardiya Çıxışı", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Selfie Təsdiqləndi · Saat: $time"),
                        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hesabdan çıxış edilsin?'),
        content: const Text('Çıxış etdikdə ana giriş səhifəsinə yönləndiriləcəksiniz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ləğv et')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıxış', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().signOut();
    }
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
