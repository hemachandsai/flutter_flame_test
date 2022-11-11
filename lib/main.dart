// import 'dart:html';
// import 'dart:ui';
import 'dart:async' as asyncPackage;

import 'package:flame/text.dart';
import 'package:flutter/material.dart';

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/rendering.dart';

void main() {
  runApp(GameWidget(game: DragEventsGame()));
}

/// The main [FlameGame] class uses [HasDraggableComponents] in order to enable
/// tap events propagation.
class DragEventsGame extends FlameGame with HasDraggableComponents {
  final _state = SingletonState();
  final _maxObjects = 10;
  @override
  Future<void> onLoad() async {
    var list = [];
    var rng = Random();
    double currentX = 20;
    double _maxSizePerObject = size.x / _maxObjects;

    for(int i=0; i <= _maxObjects; i++){
      var radius1 = rng.nextDouble() * _maxSizePerObject * 0.9;
      var radius2 = rng.nextDouble() * _maxSizePerObject * 0.9;
      var colors = [
        Color.fromRGBO(120, 0, 128, 1),
        Color.fromRGBO(30, 144, 255, 1),
        Color.fromRGBO(0, 250, 154, 1),
        Color.fromRGBO(255, 215, 0, 1),
      ];

      list.add(Star(
        n: rng.nextInt(10),
        radius1: radius1,
        radius2: radius2,
        sharpness: rng.nextDouble(),
        color: colors[i % colors.length],
        position: Vector2(currentX, 70),
      ));
      currentX += (radius1 + radius2);
    }
    addAll([
      DragTarget(),
      ...list,
      RectangleComponent(
        position: Vector2(size.x / 2 - 45, size.y - 30),
        children: [
          FpsTextComponent(),
        ],
        size: Vector2(90, 30),
        paint: Paint()..color = Colors.red,
      ),
    ]);
  }
}

/// This component is the pink-ish rectangle in the center of the game window.
/// It uses the [DragCallbacks] mixin in order to inform the game that it wants
/// to receive drag events.
class DragTarget extends PositionComponent with DragCallbacks {
  DragTarget() : super(anchor: Anchor.center);

  final _rectPaint = Paint()..color = Color.fromARGB(255, 80, 50, 149);
  Vector2 _canvasSize = Vector2(0, 0);
  /// We will store all current circles into this map, keyed by the `pointerId`
  /// of the event that created the circle.
  final Map<int, Trail> _trails = {};
  final _state = SingletonState();

  @override
  void onGameResize(Vector2 canvasSize) {
    _canvasSize = canvasSize;
    super.onGameResize(canvasSize);
    size = canvasSize - Vector2(100, 75);
    if (size.x < 100 || size.y < 100) {
      size = canvasSize * 0.9;
    }
    position = canvasSize / 2;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _rectPaint);
  }

  @override
  void onDragStart(DragStartEvent event) {
    print("dragstart");
    _state.addTouch();
    final trail = Trail(event.localPosition, _state.getActiveTouches());
    _trails[event.pointerId] = trail;
    add(trail);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    _trails[event.pointerId]!.addPoint(event.localPosition);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    print("dragend");
    _trails.remove(event.pointerId)!.end();
    _state.removeTouch();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    print("dragcancel");
    _trails.remove(event.pointerId)!.cancel();
    _state.removeTouch();
  }
}

class Trail extends Component {
  Trail(Vector2 origin, int indexValue)
      : _paths = [Path()..moveTo(origin.x, origin.y)],
        _id = indexValue,
        _opacities = [1],
        _lastPoint = origin.clone(),
        _color = HSLColor.fromAHSL(1, random.nextDouble() * 360, 1, 0.8).toColor();

  final List<Path> _paths;
  final List<double> _opacities;
  Color _color;
  late final _linePaint = Paint()..style = PaintingStyle.stroke;
  late final _circlePaint = Paint()..color = _color;
  bool _released = false;
  double _timer = 0;
  final _vanishInterval = 0.03;
  final Vector2 _lastPoint;
  final _state = SingletonState();
  int _id;
  late Color _textColor = const Color(0x000000);

  static final random = Random();
  static const lineWidth = 10.0;

  @override
  void render(Canvas canvas) {
    assert(_paths.length == _opacities.length);
    for (var i = 0; i < _paths.length; i++) {
      final path = _paths[i];
      final opacity = _opacities[i];
      if (opacity > 0) {
        _linePaint.color = _color.withOpacity(opacity);
        _textColor = _linePaint.color;
        _linePaint.strokeWidth = lineWidth * opacity;
        canvas.drawPath(path, _linePaint);
      }
    }
    canvas.drawCircle(
      _lastPoint.toOffset(),
      (lineWidth - 2) * _opacities.last + 2 * 5,
      _circlePaint,
    );
    addText(canvas);
  }

  @override
  void update(double dt) {
    // assert(_paths.length == _opacities.length);
    // _timer += dt;
    // while (_timer > _vanishInterval) {
    //   _timer -= _vanishInterval;
    //   for (var i = 0; i < _paths.length; i++) {
    //     _opacities[i] -= 0.01;
    //     if (_opacities[i] <= 0) {
    //       _paths[i].reset();
    //     }
    //   }
    //   if (!_released) {
    //     _paths.add(Path()..moveTo(_lastPoint.x, _lastPoint.y));
    //     _opacities.add(1);
    //   }
    // }
    // if (_opacities.last < 0) {
    // }
    if(_state.getActiveTouches() == 0){
      asyncPackage.Timer(Duration(seconds: 1), () => {
          removeFromParent()
      });     
    }
  }

  void addText(Canvas canvas) {
    const textStyle = TextStyle(
      color: Colors.red,
      fontSize: 30,
    );
    final textSpan = TextSpan(
      text: _id.toString(),
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 2,
      maxWidth: 2,
    );
    final xCenter = (_lastPoint.toPoint().x + 20).toDouble();
    final yCenter = (_lastPoint.toPoint().y - 15).toDouble();
    final offset = Offset(xCenter, yCenter);
    textPainter.paint(canvas, offset);
  }


  void addPoint(Vector2 point) {
    if (!point.x.isNaN) {
      for (final path in _paths) {
        path.lineTo(point.x, point.y);
      }
      _lastPoint.setFrom(point);
    }
  }

  void end() => _released = true;

  void cancel() {
    _released = true;
    _color = const Color(0xFFFFFFFF);
  }
}

class Star extends PositionComponent with DragCallbacks {
  Star({
    required int n,
    required double radius1,
    required double radius2,
    required double sharpness,
    required this.color,
    super.position,
  }) {
    _path = Path()..moveTo(radius1, 0);
    for (var i = 0; i < n; i++) {
      final p1 = Vector2(radius2, 0)..rotate(tau / n * (i + sharpness));
      final p2 = Vector2(radius2, 0)..rotate(tau / n * (i + 1 - sharpness));
      final p3 = Vector2(radius1, 0)..rotate(tau / n * (i + 1));
      _path.cubicTo(p1.x, p1.y, p2.x, p2.y, p3.x, p3.y);
    }
    _path.close();
  }

  final Color color;
  final Paint _paint = Paint();
  final Paint _borderPaint = Paint()
    ..color = const Color(0xFFffffff)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final _shadowPaint = Paint()
    ..color = const Color(0xFF000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
  late final Path _path;
  bool _isDragged = false;

  @override
  bool containsLocalPoint(Vector2 point) {
    return _path.contains(point.toOffset());
  }

  @override
  void render(Canvas canvas) {
    if (_isDragged) {
      _paint.color = color.withOpacity(0.5);
      canvas.drawPath(_path, _paint);
      canvas.drawPath(_path, _borderPaint);
    } else {
      _paint.color = color.withOpacity(1);
      canvas.drawPath(_path, _shadowPaint);
      canvas.drawPath(_path, _paint);
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    _isDragged = true;
    priority = 10;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _isDragged = false;
    priority = 0;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position += event.delta;
  }
}

const tau = 2 * pi;


class SingletonState {
  static final SingletonState _singleton = SingletonState._internal();
  int _activeTouches = 0;
  int _idCounter = 0;
  
  factory SingletonState() {
    return _singleton;
  }

  void addTouch(){
    _activeTouches++;
  }

  void removeTouch(){
    _activeTouches--;
  }

  void setIdCounter(int value){
    _idCounter = value;
  }

  int getIdCounter(){
    return _idCounter;
  }

  int getActiveTouches(){
    return _activeTouches;
  }

  SingletonState._internal();
}