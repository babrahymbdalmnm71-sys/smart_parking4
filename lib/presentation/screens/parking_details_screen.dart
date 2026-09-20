import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../logic/app_state.dart';
import '../../core/strings.dart';
import '../../data/demo_data.dart';
import '../../core/app_theme.dart';
import '../../data/models/parking_spot.dart';
import '../widgets/main_scaffold.dart';

class ParkingDetailsScreen extends StatefulWidget {
  final ParkingSpot spot;
  const ParkingDetailsScreen({super.key, required this.spot});

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  late final List<ParkingSlot> slots;
  String? selectedSlot;

  @override
  void initState() {
    super.initState();
    slots = DemoData.generateSlots(widget.spot.totalSpots, widget.spot.availableSpots);
  }

  final Map<String, IconData> amenityIcons = const {
    'كاميرات مراقبة': Icons.videocam_outlined,
    'أمن على مدار الساعة': Icons.shield_outlined,
    'مغطى': Icons.roofing_outlined,
    'شحن سيارات كهربائية': Icons.ev_station_outlined,
    'إضاءة ليلية': Icons.lightbulb_outline_rounded,
    'أمن': Icons.security_outlined,
    'غسيل سيارات': Icons.local_car_wash_outlined,
    'مكوك مجاني': Icons.directions_bus_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);
    final spot = widget.spot;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                key: ValueKey(spot.imageUrl),
                imageUrl: spot.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primary],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.local_parking_rounded, color: Colors.white, size: 80),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(spot.address,
                              style: const TextStyle(color: Colors.grey, fontSize: 13.5))),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                          child: _InfoTile(
                              icon: Icons.star_rounded,
                              iconColor: AppColors.accent,
                              label: s.rating,
                              value: '${spot.rating} (${spot.reviewsCount})')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _InfoTile(
                              icon: Icons.attach_money_rounded,
                              iconColor: AppColors.primary,
                              label: s.price,
                              value: '${spot.pricePerHour.toStringAsFixed(0)} ج.م${s.perHour}')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _InfoTile(
                              icon: Icons.access_time_rounded,
                              iconColor: Colors.blueAccent,
                              label: s.workingHours,
                              value: spot.openHours)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _InfoTile(
                              icon: Icons.local_parking_rounded,
                              iconColor: AppColors.danger,
                              label: s.availableSpots,
                              value: '${spot.availableSpots}/${spot.totalSpots}')),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(s.amenities,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: spot.amenities
                        .map((a) => Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardTheme.color,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(amenityIcons[a] ?? Icons.check_circle_outline,
                                      size: 16, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Text(a, style: const TextStyle(fontSize: 12.5)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.chooseSpot,
                          style:
                              const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          _legendDot(AppColors.primaryLight, s.available),
                          const SizedBox(width: 12),
                          _legendDot(Colors.grey.shade400, s.occupied),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: slots.length,
                    itemBuilder: (context, i) {
                      final slot = slots[i];
                      final isSelected = selectedSlot == slot.label;
                      return GestureDetector(
                        onTap: slot.isAvailable
                            ? () => setState(() => selectedSlot = slot.label)
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: !slot.isAvailable
                                ? Colors.grey.withValues(alpha: 0.25)
                                : isSelected
                                    ? AppColors.primary
                                    : AppColors.primaryLight.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            slot.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: !slot.isAvailable
                                  ? Colors.grey.shade600
                                  : isSelected
                                      ? Colors.white
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (appState.activeSession != null) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('تنبيه'),
                    content: const Text('لديك موقف نشط حالياً. يرجى إنهاء الموقف الحالي ودفع الرسوم قبل حجز مكان جديد.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('حسناً'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 1)),
                            (route) => false,
                          );
                        },
                        child: const Text('ذهاب لموقفي الحالي'),
                      ),
                    ],
                  ),
                );
                return;
              }
              if (selectedSlot == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(s.selectSlotFirst)),
                );
                return;
              }
              appState.startParking(ActiveParkingSession(
                spot: spot,
                slotLabel: selectedSlot!,
                startTime: DateTime.now(),
                pricePerHour: spot.pricePerHour,
              ));

              // إظهار تنبيه بصري بالنجاح (إشعار داخلي)
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 60),
                  title: const Text('تم الحجز بنجاح'),
                  content: Text('لقد قمت بحجز مكان في "${spot.name}" بنجاح.\n\nيمكنك الآن التوجه للموقع والبدء في الركن.'),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const MainScaffold(initialIndex: 1)),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('متابعة'),
                    ),
                  ],
                ),
              );
            },
            child: Text(s.reserveNow,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
