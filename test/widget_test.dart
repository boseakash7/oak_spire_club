import 'package:flutter_test/flutter_test.dart';

import 'package:oakspire_club/app/routes/app_routes.dart';

void main() {
  test('route constants stable', () {
    expect(AppRoutes.splash, '/splash');
    expect(AppRoutes.signUp, '/sign-up');
    expect(AppRoutes.signIn, '/sign-in');
    expect(AppRoutes.forgotPassword, '/forgot-password');
  });
}
