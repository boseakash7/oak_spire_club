import 'package:get/get.dart';

import '../../core/analytics/meta_app_events.dart';
import '../../core/storage/app_storage.dart';
import '../../core/utils/greeting_formatter.dart';
import '../../data/models/user_model.dart';

class UserSessionController extends GetxController {
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
    // Meta events follow whoever is signed in: set on sign-in, cleared on
    // sign-out, re-set when the profile changes.
    MetaAppEvents.identify(user.value);
    ever<UserModel?>(user, MetaAppEvents.identify);
  }

  void loadFromStorage() {
    final json = AppStorage.user;
    if (json == null) {
      user.value = null;
      return;
    }
    user.value = UserModel.fromJson(json);
  }

  void setUser(UserModel value) {
    user.value = value;
  }

  String get displayName =>
      GreetingFormatter.firstNameFrom(user.value?.name);

  /// Time-based greeting with the user's first name, e.g. "Good evening, Alex".
  String get greetingText =>
      GreetingFormatter.personalized(user.value?.name);
}
