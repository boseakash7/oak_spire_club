class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.totalBottles,
  });

  final String id;
  final String name;
  final String status;
  /// Backend sends unix-ish string, keep raw.
  final String createdAt;
  final int totalBottles;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      totalBottles: int.tryParse(json['total_bottles']?.toString() ?? '') ?? 0,
    );
  }
}

