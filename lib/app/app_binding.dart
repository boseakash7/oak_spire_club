import 'package:get/get.dart';

import 'core/network/api_client.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/bluebook_remote_datasource.dart';
import 'data/datasources/categories_remote_datasource.dart';
import 'data/datasources/collection_remote_datasource.dart';
import 'data/datasources/config_remote_datasource.dart';
import 'data/datasources/user_remote_datasource.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/bluebook_repository.dart';
import 'data/repositories/categories_repository.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/config_repository.dart';
import 'data/repositories/user_repository.dart';
import 'modules/session/app_config_controller.dart';
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

    Get.lazyPut<BluebookRemoteDataSource>(
      () => BluebookRemoteDataSource(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<BluebookRepository>(
      () => BluebookRepository(Get.find<BluebookRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut<CategoriesRemoteDataSource>(
      () => CategoriesRemoteDataSource(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<CategoriesRepository>(
      () => CategoriesRepository(Get.find<CategoriesRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut<ConfigRemoteDataSource>(
      () => ConfigRemoteDataSource(Get.find<ApiClient>()),
      fenix: true,
    );
    Get.lazyPut<ConfigRepository>(
      () => ConfigRepository(Get.find<ConfigRemoteDataSource>()),
      fenix: true,
    );

    // Requires ConfigRepository, so register after it.
    Get.put<AppConfigController>(AppConfigController(), permanent: true);


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

