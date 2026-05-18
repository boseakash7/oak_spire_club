import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'app/core/cache/app_cache.dart';
import 'app/core/firebase/firebase_bootstrap.dart';
import 'app/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemUiOverlayStyle);
  await GetStorage.init();
  await Hive.initFlutter();
  Get.put<AppCache>(await AppCache.init(), permanent: true);
  runApp(const OakSpireApp());
}
