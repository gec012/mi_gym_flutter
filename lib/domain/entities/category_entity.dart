class CategoryEntity {
  final String id;
  final String name;
  final String? iconUrl;

  CategoryEntity({
    required this.id,
    required this.name,
    this.iconUrl,
  });
}
