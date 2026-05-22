import 'price_formatter.dart';

class Validators {
  const Validators._();

  static final RegExp _email = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static bool isValidPassword(String value) => value.trim().length >= 8;

  static String? requiredText(String? value, {String message = 'This field is required.'}) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? positiveQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter quantity.';
    }
    final qty = int.tryParse(value.trim());
    if (qty == null || qty < 1) {
      return 'Enter a valid quantity (1 or more).';
    }
    return null;
  }

  static String? positivePrice(String? value) {
    final normalized = PriceFormatter.normalizeForApi(value ?? '');
    if (normalized == null || normalized.isEmpty) {
      return 'Enter price paid.';
    }
    final price = double.tryParse(normalized);
    if (price == null || price <= 0) {
      return 'Enter a valid price greater than 0.';
    }
    return null;
  }

  static String? fillPercent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select fill level.';
    }
    final fill = int.tryParse(value.trim());
    if (fill == null || fill < 1 || fill > 100) {
      return 'Fill level must be between 1 and 100.';
    }
    return null;
  }

  static String? dateAcquired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select date acquired.';
    }
    if (DateTime.tryParse(value.trim()) == null) {
      return 'Enter a valid date.';
    }
    return null;
  }
}

