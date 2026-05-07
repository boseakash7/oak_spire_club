class BluebookModel {
  BluebookModel({
    required this.id,
    required this.bottleName,
    this.average,
    this.low,
    this.high,
    this.status,
    this.image,
  });

  final String id;
  final String bottleName;
  final String? average;
  final String? low;
  final String? high;
  final String? status;
  final String? image;

  factory BluebookModel.fromJson(Map<String, dynamic> json) {
    return BluebookModel(
      id: json['id'].toString(),
      bottleName: (json['bottle_name'] ?? '').toString(),
      average: json['average']?.toString(),
      low: json['low']?.toString(),
      high: json['high']?.toString(),
      status: json['status']?.toString(),
      image: json['image']?.toString(),
    );
  }
}

