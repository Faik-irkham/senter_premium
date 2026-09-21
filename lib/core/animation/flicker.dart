import 'package:flutter/animation.dart';

final bulbFlicker = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 1, end: 0.2), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.9), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 0.9, end: 0.5), weight: 1),
  TweenSequenceItem(tween: Tween(begin: 0.5, end: 1), weight: 2),
]);

const bulbFlickerDuration = Duration(milliseconds: 650);
