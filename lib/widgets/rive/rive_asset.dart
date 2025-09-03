import 'package:rive/rive.dart';

class RiveAsset {
  final String artboard;
  final String stateMachineName;
  final String title;
  final String src;
  late SMIBool? input;

  RiveAsset({
    required this.src,
    required this.artboard,
    required this.stateMachineName,
    required this.title,
    this.input,
  });

  set setInput(SMIBool status) {
    input = status;
  }
}