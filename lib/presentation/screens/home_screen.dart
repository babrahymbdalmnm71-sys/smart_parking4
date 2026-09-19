import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../logic/app_state.dart';
import '../../core/strings.dart';
import '../../data/demo_data.dart';
import '../../core/app_theme.dart';
import '../../data/models/parking_spot.dart';
import 'parking_details_screen.dart';
import 'offer_details_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خدمات الموقع غير مفعلة')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم رفض إذن الوصول للموقع')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('إذن الموقع مرفوض بشكل دائم')));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      if (!context.mounted) return;
      context.read<AppState>().setUserPosition(position);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل في تحديد الموقع')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);
    final spots = DemoData.parkingSpots;

    ImageProvider? profileImageProvider;
    if (appState.profileImage != null) {
      if (appState.profileImage!.startsWith('http')) {
        profileImageProvider = NetworkImage(appState.profileImage!);
      } else {
        profileImageProvider = FileImage(File(appState.profileImage!));
      }
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    backgroundImage: profileImageProvider,
                    child: profileImageProvider == null ? const Text('👋', style: TextStyle(fontSize: 22)) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مرحباً، ${appState.userName}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(s.findYourSpot,
                            style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('لا توجد إشعارات حالياً')),
                        );
                      },
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
                      tooltip: 'الإشعارات',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _SearchBar(hint: s.searchHint),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: _RealMap(
                spots: spots, 
                onLocateMe: () => _determinePosition(context),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: _OffersCarousel(s: s),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.nearbyParking,
                      style:
                          const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(s.seeAll,
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ParkingCard(
                    spot: spots[i],
                    s: s,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ParkingDetailsScreen(spot: spots[i]),
                      ),
                    ),
                  ),
                ),
                childCount: spots.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}

class _RealMap extends StatefulWidget {
  final List<ParkingSpot> spots;
  final VoidCallback onLocateMe;
  const _RealMap({required this.spots, required this.onLocateMe});

  @override
  State<_RealMap> createState() => _RealMapState();
}

class _RealMapState extends State<_RealMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final userLoc = appState.userPosition;

    final LatLng center = userLoc != null
        ? LatLng(userLoc.latitude, userLoc.longitude)
        : LatLng(widget.spots[0].latitude, widget.spots[0].longitude);

    if (userLoc != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(userLoc.latitude, userLoc.longitude), 14.0);
      });
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smart_parking',
                ),
                MarkerLayer(
                  markers: [
                    if (userLoc != null)
                      Marker(
                        point: LatLng(userLoc.latitude, userLoc.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.person_pin_circle,
                            color: Colors.blue, size: 40),
                      ),
                    ...widget.spots.map((spot) => Marker(
                          point: LatLng(spot.latitude, spot.longitude),
                          width: 50,
                          height: 50,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        ParkingDetailsScreen(spot: spot)),
                              );
                            },
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black26, blurRadius: 4)
                                    ],
                                  ),
                                  child: Text(spot.pricePerHour.toStringAsFixed(0),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const Icon(Icons.location_on_rounded,
                                    color: AppColors.danger, size: 30),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: FloatingActionButton.small(
                onPressed: widget.onLocateMe,
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                heroTag: 'locate_me_fab',
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  const _SearchBar({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, size: 20, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _OffersCarousel extends StatelessWidget {
  final AppStrings s;
  const _OffersCarousel({required this.s});

  @override
  Widget build(BuildContext context) {
    final offers = [
      {
        'title': 'خصم 20% أول حجز',
        'color': AppColors.accent,
        'desc': 'استمتع بخصم خاص جداً عند قيامك بأول عملية حجز لموقف سيارة من خلال التطبيق.',
        'code': 'FIRST20',
        'icon': Icons.local_offer_rounded
      },
      {
        'title': 'ساعة مجانية عند التسجيل',
        'color': AppColors.primaryLight,
        'desc': 'بمناسبة انضمامك إلينا، نهديك أول ساعة مجاناً في أي موقف تختاره.',
        'code': 'FREE1HR',
        'icon': Icons.timer_outlined
      },
      {
        'title': 'عرض نهاية الأسبوع (1)',
        'color': Colors.orange,
        'desc': 'اركن سيارتك في عطلة نهاية الأسبوع بنصف السعر في مواقف مختارة.',
        'code': 'WEEKEND50',
        'icon': Icons.weekend_outlined
      },
      {
        'title': 'خصم المساء الساهر',
        'color': Colors.indigo,
        'desc': 'خصم 30% على ركن السيارات بعد الساعة 10 مساءً وحتى الفجر.',
        'code': 'NIGHT30',
        'icon': Icons.dark_mode_outlined
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.offers,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final o = offers[i];
              return InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OfferDetailsScreen(
                        title: o['title'] as String,
                        description: o['desc'] as String,
                        code: o['code'] as String,
                        color: o['color'] as Color,
                        icon: o['icon'] as IconData,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 240,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (o['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: (o['color'] as Color).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: o['color'] as Color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(o['icon'] as IconData, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              o['title'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'اضغط للتفاصيل',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ParkingCard extends StatelessWidget {
  final ParkingSpot spot;
  final AppStrings s;
  final VoidCallback onTap;
  const _ParkingCard({required this.spot, required this.s, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                spot.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  alignment: Alignment.center,
                  child: Text(spot.imageEmoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(spot.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 15, color: AppColors.accent),
                      const SizedBox(width: 2),
                      Text('${spot.rating}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Icon(Icons.place_outlined,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 2),
                      Text('${spot.distanceKm} ${s.km}',
                          style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).textTheme.bodySmall?.color)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _StatusDot(color: spot.availableSpots > 5
                          ? AppColors.primaryLight
                          : AppColors.danger),
                      const SizedBox(width: 6),
                      Text('${spot.availableSpots}/${spot.totalSpots}',
                          style: const TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${spot.pricePerHour.toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14)),
                Text(s.perHour,
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  const _StatusDot({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
