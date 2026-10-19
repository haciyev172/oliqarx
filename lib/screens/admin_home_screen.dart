import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  final User? user;
  final Map<String, dynamic> userData;

  const AdminHomeScreen({
    super.key,
    this.user,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    final adminName = userData['fullName'] ?? user?.displayName ?? "Administrator";

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('İdarəetmə Paneli', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFF7C3AED),
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(adminName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 2),
                        const Text("Səlahiyyət: Baş Administrator", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        const SizedBox(height: 4),
                        const Text("CANLI NƏZARƏT AKTİV", style: TextStyle(color: Color(0xFFC084FC), fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard("HAZIRDA İŞDƏ", "4 Nəfər", Icons.login, Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard("CƏMİ İŞÇİLƏR", "6 Qeydiyyatlı", Icons.people, Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Son Giriş-Çıxış Hərəkətləri",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            if (Firebase.apps.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('attendance_logs')
                    .orderBy('timestamp', descending: true)
                    .limit(20)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                      child: const Text("Hələlik heç bir giriş qeydi yoxdur.", style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final isCheckIn = data['type'] == 'CHECK_IN';
                      final workerName = data['worker_name'] ?? "Personel";
                      final selfieUrl = data['selfie_url'] ?? "";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (selfieUrl.isNotEmpty) {
                                  _showHighResSelfie(context, workerName, selfieUrl, isCheckIn);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: selfieUrl.isNotEmpty
                                    ? Image.network(selfieUrl, width: 50, height: 50, fit: BoxFit.cover)
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.blueGrey,
                                        child: const Icon(Icons.person, color: Colors.white),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(workerName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    isCheckIn ? "Giriş Etdi · Selfie Təsdiqli" : "Çıxış Etdi · Selfie Təsdiqli",
                                    style: TextStyle(
                                      color: isCheckIn ? Colors.greenAccent : Colors.orangeAccent,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            else
              _buildDemoAdminLogs(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoAdminLogs(BuildContext context) {
    return Column(
      children: [
        _buildDemoCard("Elmir Məmmədov", true, "20:45"),
        _buildDemoCard("Rəşad Əliyev", true, "19:30"),
        _buildDemoCard("Leyla Səmədova", true, "21:15"),
        _buildDemoCard("Orxan Həsənov", false, "18:05"),
      ],
    );
  }

  Widget _buildDemoCard(String name, bool isCheckIn, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  isCheckIn ? "Kluba Giriş · $time" : "Klubdan Çıxış · $time",
                  style: TextStyle(
                    color: isCheckIn ? Colors.greenAccent : Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showHighResSelfie(BuildContext context, String workerName, String url, bool isCheckIn) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(workerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(isCheckIn ? "Vardiya Giriş Çəkilişi" : "Vardiya Çıxış Çəkilişi", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(url, fit: BoxFit.cover, height: 280),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Bağla"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İdarəçi Hesabından Çıxış'),
        content: const Text('Oturum bağlanacaq və giriş ekranına yönləndiriləcəksiniz.'),
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

  Widget _buildMetricCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
