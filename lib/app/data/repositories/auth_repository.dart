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

  Future<void> updateProfile({
    required String userId,
    required String name,
    String? gender,
    String? oldPassword,
    String? password,
  }) async {
    await _remote.updateProfile(
      userId: userId,
      name: name,
      gender: gender,
      oldPassword: oldPassword,
      password: password,
    );

    final stored = AppStorage.user;
    if (stored != null) {
      final updated = UserModel.fromJson(stored).copyWith(
        name: name,
        gender: gender,
      );
      await AppStorage.setUser(updated.toJson());
      if (gender != null) {
        await AppStorage.setUserGender(gender);
      }
      _session().setUser(updated);
    }
  }

  Future<void> deleteAccount({required String userId}) async {
    await _remote.deleteAccount(userId: userId);
    await AppStorage.clearSession();
    _session().loadFromStorage();
  }
}
