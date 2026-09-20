import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../logic/app_state.dart';
import '../../core/strings.dart';
import '../../core/app_theme.dart';

class MyParkingScreen extends StatefulWidget {
  const MyParkingScreen({super.key});

  @override
  State<MyParkingScreen> createState() => _MyParkingScreenState();
}

class _MyParkingScreenState extends State<MyParkingScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    final appState = context.read<AppState>();
    if (appState.activeSession != null) {
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final appState = context.read<AppState>();
    final session = appState.activeSession;
    if (session != null) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(session.startTime);
        });
      }
    } else {
      if (_timer != null && _timer!.isActive) {
        _timer?.cancel();
        if (mounted) {
          setState(() {
            _elapsed = Duration.zero;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    final sec = two(d.inSeconds.remainder(60));
    return '$h:$m:$sec';
  }

  void _showEndParkingDialog() {
    final appState = context.read<AppState>();
    final session = appState.activeSession!;
    final s = AppStrings(appState.isArabic);
    final couponController = TextEditingController();
    
    double discount = 1.0;
    bool validCoupon = false;
    String paymentMethod = 'Cash'; 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final currentElapsed = DateTime.now().difference(session.startTime);
          final double hours = currentElapsed.inSeconds / 3600.0;
          // الساعة الأولى كاملة
          final double effectiveHours = hours < 1.0 ? 1.0 : hours;
          final baseCost = effectiveHours * session.pricePerHour;
          final finalCost = baseCost * discount;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text('إتمام الدفع والإنهاء'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.duration}: ${_formatDuration(currentElapsed)}'),
                  const SizedBox(height: 8),
                  Text('${s.cost}: ${finalCost.toStringAsFixed(1)} ج.م', 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18)),
                  if (validCoupon)
                    const Text('تم تطبيق الخصم بنجاح!', style: TextStyle(color: Colors.green, fontSize: 12)),
                  const Divider(height: 32),
                  
                  const Text('طريقة الدفع:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PaymentOption(
                          label: 'كاش',
                          icon: Icons.money_rounded,
                          isSelected: paymentMethod == 'Cash',
                          onTap: () => setState(() => paymentMethod = 'Cash'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PaymentOption(
                          label: 'فيزا',
                          icon: Icons.credit_card_rounded,
                          isSelected: paymentMethod == 'Visa',
                          onTap: () => setState(() => paymentMethod = 'Visa'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (!appState.hasUsedCoupon) ...[
                    const Text('كود الخصم:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: couponController,
                            enabled: !validCoupon,
                            decoration: InputDecoration(
                              hintText: 'أدخل الكود',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: validCoupon ? null : () {
                            final code = couponController.text.trim().toUpperCase();
                            if (code == 'FIRST20') {
                              setState(() {
                                discount = 0.8;
                                validCoupon = true;
                              });
                            } else if (code == 'WEEKEND50') {
                              setState(() {
                                discount = 0.5;
                                validCoupon = true;
                              });
                            } else if (code == 'FREE1HR') {
                              setState(() {
                                discount = 0.0;
                                validCoupon = true;
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('كود غير صالح'))
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                          child: Text(validCoupon ? 'تم' : 'تطبيق'),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                      ),
                      child: const Text(
                        'لقد استخدمت عرض الخصم الخاص بك مسبقاً (متاح مرة واحدة فقط).',
                        style: TextStyle(fontSize: 11, color: Colors.orange),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  _timer?.cancel();
                  await appState.endParking(
                    discountFactor: discount,
                    usedCoupon: validCoupon,
                  );
                  if (mounted) {
                    setState(() {
                      _elapsed = Duration.zero;
                    });
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text('تم الدفع بنجاح عن طريق $paymentMethod')));
                    }
                  }
                },
                child: const Text('تأكيد الدفع'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final s = AppStrings(appState.isArabic);
    final session = appState.activeSession;

    if (session != null && (_timer == null || !_timer!.isActive)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
    }

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(s.currentParking,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          if (session != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ActiveSession(
                  s: s,
                  elapsed: _elapsed,
                  formatted: _formatDuration(_elapsed),
                  onEnd: _showEndParkingDialog,
                ),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: _EmptyState(s: s),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
              child: Text(s.parkingHistory,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = appState.history[i];
                  final date = DateTime.parse(item['date'] as String);
                  final durationMins = (item['durationMinutes'] as num).toDouble();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
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
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history_rounded, color: AppColors.primary),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['parkingName'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                '${date.day}/${date.month}/${date.year} - ${durationMins < 1 ? '${(durationMins * 60).toInt()} ثانية' : '${durationMins.toStringAsFixed(1)} دقيقة'}',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text('${(item['cost'] as num).toStringAsFixed(1)} ج.م',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  );
                },
                childCount: appState.history.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppStrings s;
  const _EmptyState({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_parking_outlined,
                size: 56, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(s.noActiveParking,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(s.goFindParking,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ActiveSession extends StatelessWidget {
  final AppStrings s;
  final Duration elapsed;
  final String formatted;
  final VoidCallback onEnd;
  const _ActiveSession(
      {required this.s, required this.elapsed, required this.formatted, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final session = appState.activeSession;
    
    if (session == null) return const SizedBox.shrink();

    // حساب التكلفة الحية مع اعتبار الساعة الأولى كحد أدنى
    final double hours = elapsed.inSeconds / 3600.0;
    final double effectiveHours = hours < 1.0 ? 1.0 : hours;
    final displayCost = effectiveHours * session.pricePerHour;
    
    final spotPos = LatLng(session.spot.latitude, session.spot.longitude);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, Color(0xFF1B4332)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session.spot.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      Text('${s.spot}: ${session.slotLabel}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8), fontSize: 12.5)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Colors.greenAccent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(s.active,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(formatted,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(s.duration,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: spotPos,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smart_parking',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: spotPos,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.play_circle_outline_rounded,
                label: s.startTime,
                value:
                    '${session.startTime.hour.toString().padLeft(2, '0')}:${session.startTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.attach_money_rounded,
                label: s.cost,
                value: '${displayCost.toStringAsFixed(1)} ج.م',
                valueColor: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onEnd,
            icon: const Icon(Icons.payment_rounded),
            label: const Text('دفع وإنهاء الموقف',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _StatCard(
      {required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}
