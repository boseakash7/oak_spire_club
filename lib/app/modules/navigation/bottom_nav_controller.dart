import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final index = 0.obs;

  void setIndex(int value) => index.value = value;
}

