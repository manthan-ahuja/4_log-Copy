import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class AnimatedAvatar extends StatefulWidget {
  final bool isPasswordFocused;
  final double lookValue;
  final bool success;
  final bool failure;

  const AnimatedAvatar({
    super.key,
    required this.isPasswordFocused,
    required this.lookValue,
    required this.success,
    required this.failure,
  });

  @override
  State<AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<AnimatedAvatar> {
  SMIBool? handsUp;
  SMIBool? check;
  SMINumber? look;
  SMITrigger? successTrigger;
  SMITrigger? failTrigger;

  void _onInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');

    if (controller == null) return;

    artboard.addController(controller);

    handsUp = controller.findInput<bool>('hands_up') as SMIBool?;
    check = controller.findInput<bool>('Check') as SMIBool?;
    look = controller.findInput<double>('Look') as SMINumber?;
    successTrigger = controller.findInput<bool>('success') as SMITrigger?;
    failTrigger = controller.findInput<bool>('fail') as SMITrigger?;
  }

  @override
  void didUpdateWidget(covariant AnimatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    handsUp?.value = widget.isPasswordFocused;
    check?.value = !widget.isPasswordFocused && widget.lookValue > 0;
    look?.value = widget.lookValue.clamp(0, 100);

    if (widget.success) {
      successTrigger?.fire();
    }

    if (widget.failure) {
      failTrigger?.fire();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: RiveAnimation.asset(
        'assets/rive/login_character.riv',
        fit: BoxFit.contain,
        onInit: _onInit,
      ),
    );
  }
}
