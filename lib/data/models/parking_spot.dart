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
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerHour': pricePerHour,
      'distanceKm': distanceKm,
      'availableSpots': availableSpots,
      'totalSpots': totalSpots,
      'openHours': openHours,
      'amenities': amenities.join(','),
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory ParkingSpot.fromMap(Map<String, dynamic> map) {
    return ParkingSpot(
      id: map['id'],
      name: map['name'],
      address: map['address'],
      rating: (map['rating'] as num).toDouble(),
      reviewsCount: map['reviewsCount'],
      pricePerHour: (map['pricePerHour'] as num).toDouble(),
      distanceKm: (map['distanceKm'] as num).toDouble(),
      availableSpots: map['availableSpots'],
      totalSpots: map['totalSpots'],
      openHours: map['openHours'],
      amenities: (map['amenities'] as String).split(','),
      imageUrl: map['imageUrl'],
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  int get occupiedSpots => totalSpots - availableSpots;
  double get occupancyRatio => occupiedSpots / totalSpots;
}

class ParkingSlot {
  final String label;
  final bool isAvailable;
  const ParkingSlot({required this.label, required this.isAvailable});
}
