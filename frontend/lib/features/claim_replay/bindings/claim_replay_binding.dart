import 'package:get/get.dart';
import '../presentation/controllers/claim_replay_controller.dart';

class ClaimReplayBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClaimReplayController>(() => ClaimReplayController());
  }
}

