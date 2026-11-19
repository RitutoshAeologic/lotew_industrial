import 'package:get/get.dart';
import '../network/dio_client.dart';
import '../responsive/responsive_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ResponsiveController>(ResponsiveController(), permanent: true);
    Get.put<DioClient>(DioClient(), permanent: true);
  }
}

