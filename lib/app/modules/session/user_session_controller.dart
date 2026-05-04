import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../data/models/user_model.dart';

class UserSessionController extends GetxController {
  final user = Rxn<UserModel>();

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
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

  String get displayName {
    final name = user.value?.name?.trim();
    if (name == null || name.isEmpty) return 'there';
    return name.split(RegExp(r'\s+')).first;
  }
}
