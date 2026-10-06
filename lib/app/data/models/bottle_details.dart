/// One labelled fact on the bottle page, e.g. `Distillery · Buffalo Trace`.
class BottleFact {
  const BottleFact(this.label, this.value);

  final String label;
  final String value;
}

/// What the catalog knows about a bottle, from the API's `details` object
/// (`BlueBookHelper::details` in oakspireweb). Every field may be absent.
///
/// A server that predates `details` still sends the raw columns, so
/// [fromBottleJson] reads those when the object is missing.
class BottleDetails {
  const BottleDetails({
    this.brand,
    this.distillery,
    this.spiritType,
    this.region,
    this.ageYears,
    this.abv,
    this.msrp,
    this.isAllocated = false,
    this.bottler,
    this.bottledFor,
    this.series,
    this.label,
    this.caskType,
    this.caskNumber,
    this.vintageYear,
    this.bottledYear,
  });

  static const BottleDetails empty = BottleDetails();

  final String? brand;
  final String? distillery;
  final String? spiritType;
  final String? region;
  final double? ageYears;

  /// Percent, e.g. 43.0.
  final double? abv;
  final double? msrp;
  final bool isAllocated;
  final String? bottler;
  final String? bottledFor;
  final String? series;
  final String? label;
  final String? caskType;
  final String? caskNumber;
  final int? vintageYear;
  final int? bottledYear;

  /// From a bottle payload: its `details` object, else its raw columns.
  factory BottleDetails.fromBottleJson(Map<String, dynamic> json) {
    final nested = json['details'];
    final src = nested is Map ? Map<String, dynamic>.from(nested) : json;
    return BottleDetails(
      brand: _text(src['brand']),
      distillery: _text(src['distillery']),
      spiritType: _text(src['spirit_type']),
      region: _text(src['region']),
      ageYears: _positive(src['age_years']),
      abv: _positive(src['abv']),
      msrp: _positive(src['msrp']),
      isAllocated: _flag(src['is_allocated']),
      bottler: _text(src['bottler']),
      bottledFor: _text(src['bottled_for'] ?? src['bottle_for']),
      series: _text(src['series'] ?? src['bottler_serie']),
      label: _text(src['label']),
      caskType: _text(src['cask_type']),
      caskNumber: _text(src['cask_number']),
      vintageYear: _year(src['vintage_year']),
      bottledYear: _year(src['bottled_year'] ?? src['bottle_year']),
    );
  }

  bool get isEmpty => !isAllocated && facts.isEmpty;

  /// "12 yr", or null for no age statement. Whole years drop the ".0".
  String? get ageLabel {
    final a = ageYears;
    if (a == null) return null;
    return '${_trim(a)} yr';
  }

  /// "43%", or null.
  String? get abvLabel {
    final a = abv;
    if (a == null) return null;
    return '${_trim(a)}%';
  }

  /// Market price as a multiple of the release price (MSRP): 3.2 means the
  /// bottle trades at 3.2× what it retailed for. Null without both prices.
  double? retailMultiple(double? average) {
    final m = msrp;
    if (m == null || average == null || average <= 0) return null;
    return average / m;
  }

  /// "3.2× retail" (one decimal under 10×, whole above), or null.
  String? retailMultipleLabel(double? average) {
    final x = retailMultiple(average);
    if (x == null) return null;
    final shown = x >= 10 ? x.round().toString() : x.toStringAsFixed(1);
    return '$shown× retail';
  }

  /// Short labelled chips for a list row: age, then ABV.
  List<String> get chips => [?ageLabel, ?abvLabel];

  /// The facts for the bottle page, in reading order, blanks left out.
  List<BottleFact> get facts => [
    if (distillery != null) BottleFact('Distillery', distillery!),
    if (brand != null && brand != distillery) BottleFact('Brand', brand!),
    if (spiritType != null) BottleFact('Type', spiritType!),
    if (region != null) BottleFact('Region', region!),
    if (ageLabel != null) BottleFact('Age', ageLabel!),
    if (abvLabel != null) BottleFact('ABV', abvLabel!),
    if (msrp != null) BottleFact('Release price', '\$${_trim(msrp!)}'),
    if (vintageYear != null) BottleFact('Vintage', '$vintageYear'),
    if (bottledYear != null) BottleFact('Bottled', '$bottledYear'),
    if (bottler != null) BottleFact('Bottler', bottler!),
    if (bottledFor != null) BottleFact('Bottled for', bottledFor!),
    if (series != null) BottleFact('Series', series!),
    if (label != null) BottleFact('Label', label!),
    if (caskType != null) BottleFact('Cask type', caskType!),
    if (caskNumber != null) BottleFact('Cask no.', caskNumber!),
  ];

  /// 12.0 → "12", 43.5 → "43.5", 29.99 → "29.99".
  static String _trim(double v) {
    final s = v.toStringAsFixed(2);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String? _text(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'null') return null;
    return s;
  }

  /// A number above zero, or null: 0 is how an unfilled column reads.
  static double? _positive(dynamic v) {
    final n = double.tryParse(_text(v) ?? '');
    return n != null && n > 0 ? n : null;
  }

  static int? _year(dynamic v) {
    final n = int.tryParse(_text(v) ?? '');
    return n != null && n >= 1700 && n <= 2100 ? n : null;
  }

  static bool _flag(dynamic v) {
    final s = _text(v)?.toLowerCase();
    return s == '1' || s == 'true' || s == 'yes';
  }
}
