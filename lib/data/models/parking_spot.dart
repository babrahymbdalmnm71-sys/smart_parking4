class ParkingSpot {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int reviewsCount;
  final double pricePerHour;
  final double distanceKm;
  final int availableSpots;
  final int totalSpots;
  final String openHours;
  final List<String> amenities;
  final String imageEmoji;
  final String imageUrl;
  final double latitude;
  final double longitude;

  const ParkingSpot({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerHour,
    required this.distanceKm,
    required this.availableSpots,
    required this.totalSpots,
    required this.openHours,
    required this.amenities,
    required this.imageEmoji,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  int get occupiedSpots => totalSpots - availableSpots;
  double get occupancyRatio => occupiedSpots / totalSpots;
}

class ParkingSlot {
  final String label;
  final bool isAvailable;
  const ParkingSlot({required this.label, required this.isAvailable});
}

class ParkingHistoryItem {
  final String parkingName;
  final DateTime date;
  final Duration duration;
  final double cost;

  const ParkingHistoryItem({
    required this.parkingName,
    required this.date,
    required this.duration,
    required this.cost,
  });
}
