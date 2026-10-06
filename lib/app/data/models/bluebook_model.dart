import 'bottle_details.dart';
import 'bottle_market_stats.dart';
import 'bottle_pricing.dart';
import 'proof_json.dart';

class BluebookModel {
  BluebookModel({
    required this.id,
    required this.bottleName,
    this.average,
    this.low,
    this.high,
    this.status,
    this.image,
    this.proof,
    this.description,
    this.rating,
    this.priceMovement,
    this.isRare,
    this.pricing,
    this.details = BottleDetails.empty,
    this.market,
  });

  final String id;
  final String bottleName;
  final String? average;
  final String? low;
  final String? high;
  final String? status;
  final String? image;
  final String? proof;
  final String? description;
  final String? rating;
  final String? priceMovement;

  /// From API `is_rare`: `"1"` / `"true"` → true, `"0"` / `"false"` → false.
  final bool? isRare;

  /// What the price rests on; null from endpoints that do not send it.
  final BottlePricing? pricing;

  /// Distillery, age, ABV and the other catalog facts; empty when unknown.
  final BottleDetails details;

  /// 30/90/365-day change and 365-day range from the nightly stats; null
  /// from endpoints (or servers) that do not send `market`.
  final BottleMarketStats? market;

  factory BluebookModel.fromJson(Map<String, dynamic> json) {
    return BluebookModel(
      id: json['id'].toString(),
      bottleName: (json['bottle_name'] ?? '').toString(),
      average: _nullableString(json['average']),
      low: _nullableString(json['low']),
      high: _nullableString(json['high']),
      status: _nullableString(json['status']),
      image: _nullableString(json['image']),
      proof: ProofJson.fromMap(json),
      description: _nullableString(json['description']),
      rating: _nullableString(json['rating']),
      priceMovement: _nullableString(json['price_movement']),
      isRare: _nullableBool01(json['is_rare']),
      pricing: BottlePricing.fromJson(json['pricing']),
      details: BottleDetails.fromBottleJson(json),
      market: BottleMarketStats.fromJson(json['market']),
    );
  }

  static bool? _nullableBool01(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim().toLowerCase();
    if (s.isEmpty || s == 'null') return null;
    if (s == '1' || s == 'true' || s == 'yes') return true;
    if (s == '0' || s == 'false' || s == 'no') return false;
    return null;
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }
}
