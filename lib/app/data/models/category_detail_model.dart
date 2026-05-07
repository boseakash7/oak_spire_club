import 'category_bottle_model.dart';
import 'category_model.dart';

class CategoryDetailModel {
  CategoryDetailModel({
    required this.category,
    required this.bottles,
  });

  final CategoryModel category;
  final List<CategoryBottleModel> bottles;

  factory CategoryDetailModel.fromJson(Map<String, dynamic> json) {
    final c = json['category'];
    final b = json['bottles'];
    return CategoryDetailModel(
      category: c is Map
          ? CategoryModel.fromJson(Map<String, dynamic>.from(c))
          : CategoryModel(
              id: '',
              name: '',
              status: '',
              createdAt: '',
              totalBottles: 0,
            ),
      bottles: (b is List)
          ? b
              .whereType<Map>()
              .map(
                (e) => CategoryBottleModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : <CategoryBottleModel>[],
    );
  }
}

