import 'package:rive/rive.dart';

class RiveUtils {
  static StateMachineController? getRiveController(
    Artboard artboard, {
    required String stateMachineName,
  }) {
    StateMachineController? controller = StateMachineController.fromArtboard(
      artboard,
      stateMachineName,
    );

    if (controller != null) {
      artboard.addController(controller);
    }

    return controller;
  }
}