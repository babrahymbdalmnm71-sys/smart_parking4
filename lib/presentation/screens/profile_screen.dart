import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../logic/app_state.dart';
import '../../core/strings.dart';
import '../../core/app_theme.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (!context.mounted) return;
      context.read<AppState>().updateProfile(image: image.path);
    }
  }

  void _showEditDialog(BuildContext context, AppState appState, AppStrings s) {
    final nameController = TextEditingController(text: appState.userName);
    final phoneController = TextEditingController(text: appState.userPhone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.editProfile),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'رقم الهاتف'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          ElevatedButton(
            onPressed: () {
              appState.updateProfile(
                name: nameController.text,
                phone: phoneController.text,
              );
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);

    final totalSpent = appState.history.fold<double>(
        0, (sum, item) => sum + (item['cost'] as num).toDouble());
    final totalHours = appState.history.fold<double>(
            0,
            (sum, item) =>
                sum + (item['durationMinutes'] as num).toDouble()) /
        60.0;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(s.profile,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _ProfileHeader(
            s: s,
            onEditImage: () => _pickImage(context),
            onEditProfile: () => _showEditDialog(context, appState, s),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.statistics,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => appState.fetchHistory(),
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primary),
                tooltip: 'تحديث البيانات',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _StatBox(
                      icon: Icons.local_parking_rounded,
                      value: appState.history.length.toString(),
                      label: s.totalTrips, 
                      color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      icon: Icons.attach_money_rounded,
                      value: '${totalSpent.toStringAsFixed(1)} ج.م',
                      label: s.totalSpent,
                      color: AppColors.accent)),
              const SizedBox(width: 10),
              Expanded(
                  child: _StatBox(
                      icon: Icons.access_time_filled_rounded,
                      value: totalHours.toStringAsFixed(2), 
                      label: s.totalHours,
                      color: Colors.blueAccent)),
            ],
          ),
          const SizedBox(height: 26),
          Text(s.parkingHistory,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (appState.history.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('لا يوجد سجل مواقف حالياً', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...appState.history.map((item) {
              final date = DateTime.parse(item['date'] as String);
              final durationMins = (item['durationMinutes'] as num).toDouble();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['parkingName'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13.5)),
                          const SizedBox(height: 2),
                          Text(
                            '${date.day}/${date.month}/${date.year} · ${durationMins < 1 ? '${(durationMins * 60).toInt()} ثانية' : '${durationMins.toStringAsFixed(1)} دقيقة'}',
                            style: const TextStyle(
                                fontSize: 11.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Text('${(item['cost'] as num).toStringAsFixed(1)} ج.م',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
              );
            }),
          const SizedBox(height: 20),
          if (appState.isAdmin) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                label: const Text('لوحة تحكم الأدمن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade800,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: AppColors.primary,
                  secondary: const Icon(Icons.notifications_none_rounded),
                  title: Text(s.notifications),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: appState.isDarkMode,
                  onChanged: (v) => context.read<AppState>().toggleDarkMode(v),
                  activeThumbColor: AppColors.primary,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text(s.darkMode),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(s.language),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(appState.isArabic ? s.arabic : s.english,
                          style: const TextStyle(color: Colors.grey)),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                  onTap: () => _showLanguageSheet(context, appState, s),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: const Text('أرسل رأيك أو شكوى'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => _showFeedbackDialog(context, appState),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(s.about),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text(s.appName),
                      content: Text(s.aboutText),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: Text(s.logout),
                  content: Text(s.logoutConfirm),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        appState.logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Text(s.logout,
                          style: const TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: Text(s.logout, style: const TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('أرسل رأيك أو شكوى'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'اكتب رسالتك هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                appState.sendFeedback(controller.text);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إرسال رسالتك بنجاح للادمن')),
                );
              }
            },
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, AppState appState, AppStrings s) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(s.arabic),
              trailing: appState.isArabic
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                context.read<AppState>().toggleLanguage(true);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(s.english),
              trailing: !appState.isArabic
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () {
                context.read<AppState>().toggleLanguage(false);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final AppStrings s;
  final VoidCallback onEditImage;
  final VoidCallback onEditProfile;
  const _ProfileHeader(
      {required this.s, required this.onEditImage, required this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    ImageProvider profileImageProvider;
    if (appState.profileImage != null) {
      if (appState.profileImage!.startsWith('http')) {
        profileImageProvider = NetworkImage(appState.profileImage!);
      } else {
        profileImageProvider = FileImage(File(appState.profileImage!));
      }
    } else {
      profileImageProvider = const AssetImage('assets/placeholder.png'); // Default if no image
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1B4332)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEditImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  backgroundImage: appState.profileImage != null ? profileImageProvider : null,
                  child: appState.profileImage == null
                      ? const Text('👤', style: TextStyle(fontSize: 28))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt,
                        size: 14, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appState.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(appState.userPhone,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5)),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon; 
  final String value;
  final String label;
  final Color color;
  
  const _StatBox(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10.5, color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
