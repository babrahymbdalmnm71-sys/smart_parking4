import 'models/parking_spot.dart';

class DemoData {
  static final List<ParkingSpot> parkingSpots = [
    const ParkingSpot(
      id: 'p1',
      name: 'موقف سيتي مول',
      address: 'شارع التحرير، وسط البلد',
      rating: 4.6,
      reviewsCount: 328,
      pricePerHour: 8.0,
      distanceKm: 0.6,
      availableSpots: 24,
      totalSpots: 60,
      openHours: '24 ساعة',
      amenities: ['كاميرات مراقبة', 'أمن على مدار الساعة', 'مغطى', 'شحن سيارات كهربائية'],
      imageEmoji: '🏬',
      imageUrl: 'https://images.unsplash.com/photo-1573348722427-f1d6819fdf98?auto=format&fit=crop&q=80&w=800',
      latitude: 30.0444,
      longitude: 31.2357,
    ),
    const ParkingSpot(
      id: 'p2',
      name: 'موقف برج النيل',
      address: 'كورنيش النيل',
      rating: 4.3,
      reviewsCount: 190,
      pricePerHour: 10.0,
      distanceKm: 1.2,
      availableSpots: 8,
      totalSpots: 40,
      openHours: '6 ص - 12 م',
      amenities: ['إضاءة ليلية', 'أمن', 'غسيل سيارات'],
      imageEmoji: '🌆',
      imageUrl: 'https://images.unsplash.com/photo-1541963463532-d68292c34b19?auto=format&fit=crop&q=80&w=800', // Beautiful Nile View/Cairo Tower
      latitude: 30.0400,
      longitude: 31.2200,
    ),
    const ParkingSpot(
      id: 'p3',
      name: 'موقف المطار',
      address: 'طريق المطار الرئيسي',
      rating: 4.8,
      reviewsCount: 512,
      pricePerHour: 12.0,
      distanceKm: 3.4,
      availableSpots: 45,
      totalSpots: 120,
      openHours: '24 ساعة',
      amenities: ['مكوك مجاني', 'كاميرات مراقبة', 'مغطى', 'أمن على مدار الساعة'],
      imageEmoji: '✈️',
      imageUrl: 'https://images.unsplash.com/photo-1506521781263-d8422e82f27a?auto=format&fit=crop&q=80&w=800',
      latitude: 30.1122,
      longitude: 31.3995,
    ),
    const ParkingSpot(
      id: 'p4',
      name: 'موقف الجامعة',
      address: 'شارع الجامعة',
      rating: 4.1,
      reviewsCount: 87,
      pricePerHour: 5.0,
      distanceKm: 2.0,
      availableSpots: 3,
      totalSpots: 30,
      openHours: '7 ص - 10 م',
      amenities: ['أمن', 'إضاءة ليلية'],
      imageEmoji: '🎓',
      imageUrl: 'https://images.unsplash.com/photo-1492538368677-f6e0afe31dcc?auto=format&fit=crop&q=80&w=800', // Academic campus
      latitude: 30.0263,
      longitude: 31.2114,
    ),
  ];

  static List<ParkingSlot> generateSlots(int total, int available) {
    final List<ParkingSlot> slots = [];
    for (int i = 0; i < total; i++) {
      final label = 'A${(i + 1).toString().padLeft(2, '0')}';
      slots.add(ParkingSlot(label: label, isAvailable: i < available));
    }
    slots.shuffle();
    return slots;
  }
}
