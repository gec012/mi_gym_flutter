enum ClassIntensity { low, medium, high }

class GymClassEntity {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String categoryId;
  final ClassIntensity intensity;
  final int durationMinutes;
  final double basePrice;

  GymClassEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    required this.intensity,
    required this.durationMinutes,
    required this.basePrice,
  });
}
