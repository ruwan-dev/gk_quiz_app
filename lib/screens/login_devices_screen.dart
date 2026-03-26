import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class LoginDevicesScreen extends StatelessWidget {
  const LoginDevicesScreen({super.key});

  IconData _getBrowserIcon(String browser) {
    switch (browser.toLowerCase()) {
      case 'chrome':
        return Icons.language_rounded;
      case 'firefox':
        return Icons.local_fire_department_rounded;
      case 'safari':
        return Icons.travel_explore_rounded;
      case 'edge':
        return Icons.explore_rounded;
      default:
        return Icons.public_rounded;
    }
  }

  IconData _getMethodIcon(String method) {
    if (method.toLowerCase().contains('google')) return Icons.g_mobiledata_rounded;
    return Icons.email_outlined;
  }

  Color _getMethodColor(String method) {
    if (method.toLowerCase().contains('google')) return const Color(0xFFEA4335);
    if (method.toLowerCase().contains('register')) return const Color(0xFF10B981);
    return const Color(0xFF38BDF8);
  }

  String _getMethodLabel(String method) {
    switch (method) {
      case 'Google':
        return 'Google';
      case 'Email':
        return 'Email Sign‑In';
      case 'Email-Register':
        return 'Registered';
      default:
        return method;
    }
  }

  Future<void> _clearAllSessions(BuildContext context, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Sessions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will remove all saved login session records. This does not sign you out from active sessions.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('login_devices')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All session records cleared.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: Text('Not signed in.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Login Devices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            tooltip: 'Clear All Sessions',
            onPressed: () => _clearAllSessions(context, user.uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('login_devices')
            .orderBy('loginAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.devices_rounded, size: 64, color: Colors.white.withOpacity(0.08)),
                  const SizedBox(height: 16),
                  const Text(
                    'No login sessions found.',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your sign-in history will appear here.',
                    style: TextStyle(color: Colors.white24, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String browser = data['browser'] ?? 'Unknown Browser';
              final String os = data['os'] ?? 'Unknown OS';
              final String method = data['method'] ?? 'Unknown';
              final Timestamp? loginAt = data['loginAt'] as Timestamp?;
              final String dateStr = loginAt != null
                  ? DateFormat('MMM d, y  •  h:mm a').format(loginAt.toDate().toLocal())
                  : 'Unknown time';

              final bool isFirst = index == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isFirst
                      ? const Color(0xFF38BDF8).withOpacity(0.07)
                      : Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isFirst
                        ? const Color(0xFF38BDF8).withOpacity(0.3)
                        : Colors.white.withOpacity(0.07),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Browser icon circle
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF38BDF8).withOpacity(0.1),
                          border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.2)),
                        ),
                        child: Icon(
                          _getBrowserIcon(browser),
                          color: const Color(0xFF38BDF8),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  browser,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (isFirst) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                                    ),
                                    child: const Text(
                                      'Latest',
                                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$os  •  ${data['platform'] ?? 'Web'}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateStr,
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // Method badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getMethodColor(method).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _getMethodColor(method).withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getMethodIcon(method), color: _getMethodColor(method), size: 13),
                            const SizedBox(width: 5),
                            Text(
                              _getMethodLabel(method),
                              style: TextStyle(
                                color: _getMethodColor(method),
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
              );
            },
          );
        },
      ),
    );
  }
}
