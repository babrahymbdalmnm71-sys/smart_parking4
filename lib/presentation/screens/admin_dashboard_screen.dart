import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/app_state.dart';
import '../../data/models/parking_spot.dart';
import '../../core/app_theme.dart';
import '../widgets/app_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  void _showSpotDialog(BuildContext context, {ParkingSpot? spot}) {
    final appState = context.read<AppState>();
    final isEdit = spot != null;
    
    final idController = TextEditingController(text: spot?.id ?? 'p${DateTime.now().millisecondsSinceEpoch}');
    final nameController = TextEditingController(text: spot?.name ?? '');
    final addressController = TextEditingController(text: spot?.address ?? '');
    final priceController = TextEditingController(text: spot?.pricePerHour.toString() ?? '20');
    final imageController = TextEditingController(text: spot?.imageUrl ?? '');
    final latController = TextEditingController(text: spot?.latitude.toString() ?? '30.0');
    final lngController = TextEditingController(text: spot?.longitude.toString() ?? '31.0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'تعديل موقف' : 'إضافة موقف جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الموقف')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'العنوان')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'السعر بالساعة'), keyboardType: TextInputType.number),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'رابط الصورة (URL)')),
              TextField(controller: latController, decoration: const InputDecoration(labelText: 'خط العرض (Latitude)'), keyboardType: TextInputType.number),
              TextField(controller: lngController, decoration: const InputDecoration(labelText: 'خط الطول (Longitude)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final newSpot = ParkingSpot(
                id: idController.text,
                name: nameController.text,
                address: addressController.text,
                pricePerHour: double.tryParse(priceController.text) ?? 20.0,
                imageUrl: imageController.text.trim(),
                latitude: double.tryParse(latController.text) ?? 30.0,
                longitude: double.tryParse(lngController.text) ?? 31.0,
                rating: spot?.rating ?? 4.5,
                reviewsCount: spot?.reviewsCount ?? 0,
                distanceKm: spot?.distanceKm ?? 1.0,
                availableSpots: spot?.availableSpots ?? 50,
                totalSpots: spot?.totalSpots ?? 50,
                openHours: spot?.openHours ?? '24 ساعة',
                amenities: spot?.amenities ?? ['أمن', 'كاميرات مراقبة'],
              );
              await appState.addOrUpdateSpot(newSpot);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إعادة ضبط المواقف'),
        content: const Text(
            'هل أنت متأكد من رغبتك في مسح كافة التعديلات الحالية وإعادة تحميل المواقف الافتراضية من الكود؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppState>().resetSpotsToDefault();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('تم إعادة الضبط بنجاح')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إعادة ضبط الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم الأدمن'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'إعادة ضبط المواقف',
              onPressed: () => _showResetDialog(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.local_parking), text: 'المواقف'),
            Tab(icon: Icon(Icons.feedback_outlined), text: 'الشكاوي والآراء'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 0 ? FloatingActionButton(
        onPressed: () => _showSpotDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Spots Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appState.parkingSpots.length,
            itemBuilder: (context, i) {
              final spot = appState.parkingSpots[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppImage(
                      imageUrl: spot.imageUrl,
                      width: 50,
                      height: 50,
                      iconSize: 20,
                    ),
                  ),
                  title: Text(spot.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${spot.pricePerHour} ج.م / ساعة'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => _showSpotDialog(context, spot: spot),
                  ),
                ),
              );
            },
          ),
          
          // Feedback Tab
          appState.feedback.isEmpty
              ? const Center(child: Text('لا توجد شكاوي أو آراء حالياً'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appState.feedback.length,
                  itemBuilder: (context, i) {
                    final item = appState.feedback[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        title: Text(item['userName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['message']),
                            const SizedBox(height: 4),
                            Text('رقم الهاتف: ${item['userPhone']}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                        trailing: const Icon(Icons.message_outlined, color: AppColors.primary),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
