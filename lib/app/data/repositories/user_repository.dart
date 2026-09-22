import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../modules/session/user_session_controller.dart';
import '../datasources/user_remote_datasource.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository(this._remote);
  final UserRemoteDataSource _remote;

  Future<UserModel> refreshUserById(String id) async {
    final user = await _remote.getById(id);
    await AppStorage.saveSession(user.toJson());

    if (!Get.isRegistered<UserSessionController>()) {
      Get.put<UserSessionController>(UserSessionController(), permanent: true);
    }
    Get.find<UserSessionController>().setUser(user);
    return user;
  }
}
