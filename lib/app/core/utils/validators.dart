class Validators {
  const Validators._();

  static final RegExp _email = RegExp(
    r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  );

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());
  static bool isValidPassword(String value) => value.trim().length >= 8;
}

