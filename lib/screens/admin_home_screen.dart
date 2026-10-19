import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class AdminHomeScreen extends StatefulWidget {
  final User? user;
  final Map<String, dynamic> userData;

  const AdminHomeScreen({
    super.key,
    this.user,
    required this.userData,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  static const Color _background = Color(0xFF0F172A);
  static const Color _card = Color(0xFF1E293B);
  static const Color _border = Color(0xFF334155);

  @override
  Widget build(BuildContext context) {
    final adminName = (widget.userData['fullName'] ??
            widget.user?.displayName ??
            'Administrator')
        .toString();

    final pages = [
      _buildDashboard(adminName),
      _buildPlaceholder('Personal', Icons.people_outline,
          'İşçilərin idarə edilməsi'),
      _buildHistoryPage(),
      _buildPlaceholder('QR Kodu', Icons.qr_code_2,
          'QR kod idarəetməsi'),
      _buildPlaceholder('Parametrlər', Icons.settings_outlined,
          'Tətbiq parametrləri'),
    ];

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'İdarəetmə Paneli'
              : [
                  'Ana Səhifə',
                  'Personal',
                  'Tarixçə',
                  'QR Kodu',
                  'Parametrlər',
                ][_selectedIndex],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _card,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Hesabdan çıxış',
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: _card,
        selectedItemColor: const Color(0xFF60A5FA),
        unselectedItemColor: Colors.white54,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Ana Səhifə',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Personal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Tarixçə',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2),
            label: 'QR Kodu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Parametrlər',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(String adminName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFF7C3AED),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Səlahiyyət: Baş Administrator',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'CANLI NƏZARƏT AKTİV',
                        style: TextStyle(
                          color: Color(0xFFC084FC),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildWorkingCountCard()),
              const SizedBox(width: 12),
              Expanded(child: _buildTotalUsersCard()),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Son Giriş-Çıxış Hərəkətləri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _buildRecentLogs(limit: 5),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _selectedIndex = 2),
            child: const Text('Bütün tarixçəyə bax'),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalUsersCard() {
    if (Firebase.apps.isEmpty) {
      return _buildMetricCard(
        'CƏMİ İŞÇİLƏR',
        'Firebase əlçatan deyil',
        Icons.people,
        Colors.blue,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMetricCard(
            'CƏMİ İŞÇİLƏR',
            'Məlumat alınmadı',
            Icons.people,
            Colors.blue,
          );
        }

        if (!snapshot.hasData) {
          return _buildMetricCard(
            'CƏMİ İŞÇİLƏR',
            'Yüklənir...',
            Icons.people,
            Colors.blue,
          );
        }

        // Adminlər də daxil olmaqla bütün qeydiyyatlı profillər.
        final count = snapshot.data!.docs.length;

        return _buildMetricCard(
          'CƏMİ İŞÇİLƏR',
          '$count Qeydiyyatlı',
          Icons.people,
          Colors.blue,
        );
      },
    );
  }

  Widget _buildWorkingCountCard() {
    if (Firebase.apps.isEmpty) {
      return _buildMetricCard(
        'HAZIRDA İŞDƏ',
        'Məlumat yoxdur',
        Icons.login,
        Colors.green,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('attendance_logs')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildMetricCard(
            'HAZIRDA İŞDƏ',
            'Məlumat alınmadı',
            Icons.login,
            Colors.green,
          );
        }

        if (!snapshot.hasData) {
          return _buildMetricCard(
            'HAZIRDA İŞDƏ',
            'Yüklənir...',
            Icons.login,
            Colors.green,
          );
        }

        final latestByUser = <String, Map<String, dynamic>>{};

        for (final doc in snapshot.data!.docs) {
          final data = doc.data();
          final uid = (data['worker_id'] ??
                  data['user_id'] ??
                  data['uid'] ??
                  '')
              .toString();

          if (uid.isEmpty || latestByUser.containsKey(uid)) {
            continue;
          }

          latestByUser[uid] = data;
        }

        final working = latestByUser.values
            .where((data) => data['type'] == 'CHECK_IN')
            .length;

        return _buildMetricCard(
          'HAZIRDA İŞDƏ',
          '$working Nəfər',
          Icons.login,
          Colors.green,
        );
      },
    );
  }

  Widget _buildRecentLogs({int limit = 20}) {
    if (Firebase.apps.isEmpty) {
      return _emptyMessage('Firebase bağlantısı yoxdur.');
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('attendance_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _emptyMessage(
            'Giriş-çıxış məlumatları oxunmadı. '
            'Firestore qaydalarını yoxlayın.',
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return _emptyMessage('Hələlik heç bir giriş qeydi yoxdur.');
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();

            final isCheckIn = data['type'] == 'CHECK_IN';
            final workerName =
                (data['worker_name'] ?? 'İşçi').toString();
            final selfieUrl =
                (data['selfie_url'] ?? '').toString();
            final time = _formatTimestamp(data);

            return InkWell(
              onTap: () => _showLogDetails(
                context,
                workerName,
                data,
                selfieUrl,
                isCheckIn,
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: selfieUrl.isNotEmpty
                          ? Image.network(
                              selfieUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
    _personPlaceholder(),
                            )
                          : _personPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isCheckIn
                                ? 'Kluba giriş · $time'
                                : 'Klubdan çıxış · $time',
                            style: TextStyle(
                              color: isCheckIn
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Bütün Giriş-Çıxış Tarixçəsi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentLogs(limit: 100),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(
    String title,
    IconData icon,
    String description,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF60A5FA), size: 56),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _personPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      color: const Color(0xFF334155),
      child: const Icon(Icons.person, color: Colors.white70),
    );
  }

  Widget _emptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white70),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _formatTimestamp(Map<String, dynamic> data) {
    final value = data['timestamp'] ?? data['created_at'];

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) return 'Saat məlum deyil';

    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day.$month.${local.year} $hour:$minute';
  }

  void _showLogDetails(
    BuildContext context,
    String workerName,
    Map<String, dynamic> data,
    String selfieUrl,
    bool isCheckIn,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: _background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCheckIn ? 'Kluba giriş' : 'Klubdan çıxış',
                style: TextStyle(
                  color: isCheckIn
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tarix və saat: ${_formatTimestamp(data)}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (data['qr_id'] != null) ...[
                const SizedBox(height: 6),
                Text(
                  'QR ID: ${data['qr_id']}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
              const SizedBox(height: 16),
              if (selfieUrl.isNotEmpty)
  ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.network(
      selfieUrl,
      fit: BoxFit.contain,
      height: 280,
      errorBuilder: (context, error, stackTrace) =>
          _emptyMessage(
        'Selfie fotosunu yükləmək mümkün olmadı.',
      ),
    ),
  )
else
  _emptyMessage('Bu qeydə aid selfie tapılmadı.'),

const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Bağla'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İdarəçi hesabından çıxış'),
        content: const Text(
          'Oturum bağlanacaq və giriş ekranına yönləndiriləcəksiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ləğv et'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıxış'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
    }
  }
}
