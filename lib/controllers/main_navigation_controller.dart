import 'package:get/get.dart';

class MainNavigationController extends GetxController {
  // .obs membuat variabel ini reaktif
  var currentIndex = 0.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }
}