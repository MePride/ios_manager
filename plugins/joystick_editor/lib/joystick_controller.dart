// 摇杆控制器

import 'dart:math' as _math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'circle_view.dart';

typedef JoystickDirectionCallback = void Function(
    double degrees, double distance);

// ignore: must_be_immutable
class JoystickController extends StatelessWidget {
  final double size;
  final Color iconsColor;
  final Color backgroundColor;
  final Color innerCircleColor;
  final double opacity;
  final JoystickDirectionCallback onDirectionChanged;
  final Duration interval;
  final bool showArrows;

  DateTime _callbackTimestamp;

  JoystickController({
    this.size,
    this.iconsColor = Colors.blue,
    this.backgroundColor = Colors.transparent,
    this.innerCircleColor = Colors.red,
    this.opacity,
    this.onDirectionChanged,
    this.interval,
    this.showArrows = true,
  });

  @override
  Widget build(BuildContext context) {
    double actualSize = size != null
        ? size
        : _math.min(MediaQuery.of(context).size.width,
                MediaQuery.of(context).size.height) *
            0.5;
    double innerCircleSize = actualSize / 2;
    Offset lastPosition = Offset(innerCircleSize, innerCircleSize);
    Offset joystickInnerPosition = _calculatePositionOfInnerCircle(
        lastPosition, innerCircleSize, actualSize, Offset(0, 0));

    return Center(
      child: StatefulBuilder(
        builder: (context, setState) {
          Widget joystick = Stack(
            children: <Widget>[
              CircleView.joystickCircle(
                actualSize,
                backgroundColor,
              ),
              Positioned(
                child: CircleView.joystickInnerCircle(
                  actualSize / 2,
                  innerCircleColor,
                ),
                top: joystickInnerPosition.dy,
                left: joystickInnerPosition.dx,
              ),
              if (showArrows) ...createArrows(),
            ],
          );

          return GestureDetector(
            onPanStart: (details) {
              _callbackTimestamp = _processGesture(actualSize, actualSize / 2,
                  details.localPosition, _callbackTimestamp);
              setState(() => lastPosition = details.localPosition);
            },
            onPanEnd: (details) {
              _callbackTimestamp = null;
              if (onDirectionChanged != null) {
                onDirectionChanged(0, 0);
              }
              joystickInnerPosition = _calculatePositionOfInnerCircle(
                  Offset(innerCircleSize, innerCircleSize),
                  innerCircleSize,
                  actualSize,
                  Offset(0, 0));
              setState(() =>
                  lastPosition = Offset(innerCircleSize, innerCircleSize));
            },
            onPanUpdate: (details) {
              _callbackTimestamp = _processGesture(actualSize, actualSize / 2,
                  details.localPosition, _callbackTimestamp);
              joystickInnerPosition = _calculatePositionOfInnerCircle(
                  lastPosition,
                  innerCircleSize,
                  actualSize,
                  details.localPosition);

              setState(() => lastPosition = details.localPosition);
            },
            child: (opacity != null)
                ? Opacity(opacity: opacity, child: joystick)
                : joystick,
          );
        },
      ),
    );
  }

  List<Widget> createArrows() {
    return [
      Positioned(
        child: Icon(
          Icons.keyboard_arrow_up,
          color: iconsColor,
        ),
        top: 12.0,
        left: 0.0,
        right: 0.0,
      ),
      Positioned(
        child: Icon(
          Icons.keyboard_arrow_left,
          color: iconsColor,
        ),
        top: 0.0,
        bottom: 0.0,
        left: 12.0,
      ),
      Positioned(
        child: Icon(
          Icons.keyboard_arrow_right,
          color: iconsColor,
        ),
        top: 0.0,
        bottom: 0.0,
        right: 12.0,
      ),
      Positioned(
        child: Icon(
          Icons.keyboard_arrow_down,
          color: iconsColor,
        ),
        bottom: 12.0,
        left: 0.0,
        right: 0.0,
      ),
    ];
  }

  DateTime _processGesture(double size, double ignoreSize, Offset offset,
      DateTime callbackTimestamp) {
    double middle = size / 2.0;

    double angle = _math.atan2(offset.dy - middle, offset.dx - middle);
    double degrees = angle * 180 / _math.pi + 90;
    if (offset.dx < middle && offset.dy < middle) {
      degrees = 360 + degrees;
    }

    double dx = _math.max(0, _math.min(offset.dx, size));
    double dy = _math.max(0, _math.min(offset.dy, size));

    double distance =
        _math.sqrt(_math.pow(middle - dx, 2) + _math.pow(middle - dy, 2));

    double normalizedDistance = _math.min(distance / (size / 2), 1.0);

    DateTime _callbackTimestamp = callbackTimestamp;
    if (onDirectionChanged != null &&
        _canCallOnDirectionChanged(callbackTimestamp)) {
      _callbackTimestamp = DateTime.now();
      onDirectionChanged(degrees, normalizedDistance);
    }

    return _callbackTimestamp;
  }

  bool _canCallOnDirectionChanged(DateTime callbackTimestamp) {
    if (interval != null && callbackTimestamp != null) {
      int intervalMilliseconds = interval.inMilliseconds;
      int timestampMilliseconds = callbackTimestamp.millisecondsSinceEpoch;
      int currentTimeMilliseconds = DateTime.now().millisecondsSinceEpoch;

      if (currentTimeMilliseconds - timestampMilliseconds <=
          intervalMilliseconds) {
        return false;
      }
    }

    return true;
  }

  Offset _calculatePositionOfInnerCircle(
      Offset lastPosition, double innerCircleSize, double size, Offset offset) {
    double middle = size / 2.0;

    double angle = _math.atan2(offset.dy - middle, offset.dx - middle);
    double degrees = angle * 180 / _math.pi;
    if (offset.dx < middle && offset.dy < middle) {
      degrees = 360 + degrees;
    }
    bool isStartPosition = lastPosition.dx == innerCircleSize &&
        lastPosition.dy == innerCircleSize;
    double lastAngleRadians =
        (isStartPosition) ? 0 : (degrees) * (_math.pi / 180.0);

    var rBig = size / 2;
    var rSmall = innerCircleSize / 2;

    var x = (lastAngleRadians == -1)
        ? rBig - rSmall
        : (rBig - rSmall) + (rBig - rSmall) * _math.cos(lastAngleRadians);
    var y = (lastAngleRadians == -1)
        ? rBig - rSmall
        : (rBig - rSmall) + (rBig - rSmall) * _math.sin(lastAngleRadians);

    var xPosition = lastPosition.dx - rSmall;
    var yPosition = lastPosition.dy - rSmall;

    var angleRadianPlus = lastAngleRadians + _math.pi / 2;
    if (angleRadianPlus < _math.pi / 2) {
      if (xPosition > x) {
        xPosition = x;
      }
      if (yPosition < y) {
        yPosition = y;
      }
    } else if (angleRadianPlus < _math.pi) {
      if (xPosition > x) {
        xPosition = x;
      }
      if (yPosition > y) {
        yPosition = y;
      }
    } else if (angleRadianPlus < 3 * _math.pi / 2) {
      if (xPosition < x) {
        xPosition = x;
      }
      if (yPosition > y) {
        yPosition = y;
      }
    } else {
      if (xPosition < x) {
        xPosition = x;
      }
      if (yPosition < y) {
        yPosition = y;
      }
    }
    return Offset(xPosition, yPosition);
  }
}
