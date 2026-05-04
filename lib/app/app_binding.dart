import 'package:get/get.dart';

import 'core/network/api_client.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/collection_remote_datasource.dart';
import 'data/datasources/user_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/user_repository.dart';
import 'modules/session/user_session_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<UserSessionController>(UserSessionController(), permanent: true);
    Get.lazyPut<ApiClient>(() => ApiClient(), fenix: true);
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<AuthRepository>(
      () => AuthRepository(Get.find<AuthRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut<CollectionRemoteDataSource>(
      () => CollectionRemoteDataSource(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<CollectionRepository>(
      () => CollectionRepository(Get.find<CollectionRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut<UserRemoteDataSource>(
      () => UserRemoteDataSource(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<UserRepository>(
      () => UserRepository(Get.find<UserRemoteDataSource>()),
      fenix: true,
    );
  }
}

