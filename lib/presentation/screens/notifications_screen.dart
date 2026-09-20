import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/app_state.dart';
import '../../core/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: appState.notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: appState.notifications.length,
              itemBuilder: (context, i) {
                final notif = appState.notifications[i];
                final time = DateTime.parse(notif['time']);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary),
                    ),
                    title: Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notif['body']),
                        const SizedBox(height: 4),
                        Text('${time.hour}:${time.minute} - ${time.day}/${time.month}', 
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
