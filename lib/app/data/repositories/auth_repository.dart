import 'package:get/get.dart';

import '../../core/storage/app_storage.dart';
import '../../modules/session/user_session_controller.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._remote);
  final AuthRemoteDataSource _remote;

  UserSessionController _session() {
    if (!Get.isRegistered<UserSessionController>()) {
      Get.put<UserSessionController>(UserSessionController(), permanent: true);
    }
    return Get.find<UserSessionController>();
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final user = await _remote.login(email: email, password: password);
    await AppStorage.setUserId(user.id);
    await AppStorage.setUser(user.toJson());
    _session().setUser(user);
    return user;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    bool subscribe = false,
  }) async {
    final user = await _remote.register(
      fullName: fullName,
      email: email,
      password: password,
      subscribe: subscribe,
    );
    await AppStorage.setUserId(user.id);
    await AppStorage.setUser(user.toJson());
    _session().setUser(user);
    return user;
  }
}
