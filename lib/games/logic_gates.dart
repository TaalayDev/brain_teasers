import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

class LogicGatesGame extends Forge2DGame {
  final Function(int score) onScoreUpdate;
  final VoidCallback onComplete;

  late List<GateBody> gates = [];
  late List<Wire> wires = [];
  late InputNode inputNode;
  late OutputNode outputNode;
  late Vector2 gameSize;
  int score = 1000;
  bool isComplete = false;

  LogicGatesGame({
    required this.onScoreUpdate,
    required this.onComplete,
  }) : super(gravity: Vector2.zero());

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Get visible game size
    final size = camera.visibleWorldRect;
    gameSize = Vector2(size.width, size.height);

    // Calculate positions based on game size
    final leftX = -gameSize.x / 4;
    final rightX = gameSize.x / 4;
    final gateSpacing = gameSize.y / 6;

    // Add input node
    inputNode = InputNode(Vector2(leftX, 0));
    world.add(inputNode);

    // Add output node
    outputNode = OutputNode(Vector2(rightX, 0));
    world.add(outputNode);

    // Generate gates with proper spacing
    _addInitialGates(leftX + 4, gateSpacing);
  }

  void _addInitialGates(double x, double spacing) {
    final gateTypes = [GateType.AND, GateType.OR, GateType.NOT];

    for (int i = 0; i < gateTypes.length; i++) {
      final gate = GateBody(
        position: Vector2(x, (i - 1) * spacing),
        gateType: gateTypes[i],
        onDragEnd: _handleGateDragEnd,
      );
      gates.add(gate);
      world.add(gate);
    }
  }

  void _handleGateDragEnd(GateBody gate, Vector2 position) {
    final snapDistance = gameSize.x / 20;

    if (position.distanceTo(inputNode.position) < snapDistance) {
      gate.body.setTransform(inputNode.position + Vector2(2, 0), 0);
      _connectGateToInput(gate);
    } else if (position.distanceTo(outputNode.position) < snapDistance) {
      gate.body.setTransform(outputNode.position + Vector2(-2, 0), 0);
      _connectGateToOutput(gate);
    }

    _checkSolution();
  }

  void _connectGateToInput(GateBody gate) {
    final wire = Wire(start: inputNode.position, end: gate.inputPosition);
    wires.add(wire);
    world.add(wire);
  }

  void _connectGateToOutput(GateBody gate) {
    final wire = Wire(start: gate.outputPosition, end: outputNode.position);
    wires.add(wire);
    world.add(wire);
  }

  void _checkSolution() {
    // Check if circuit is complete and correct
    bool isValid = _validateCircuit();
    if (isValid) {
      isComplete = true;
      onComplete();
    }
  }

  bool _validateCircuit() {
    // Validate circuit logic here
    return false; // Placeholder
  }
}

enum GateType { AND, OR, NOT }

class GateBody extends BodyComponent with DragCallbacks {
  final GateType gateType;
  final void Function(GateBody gate, Vector2 position) _onDragEnd;
  Vector2 get inputPosition => position + Vector2(-1, 0);
  Vector2 get outputPosition => position + Vector2(1, 0);
  final Vector2 _position;

  GateBody({
    required Vector2 position,
    required this.gateType,
    required void Function(GateBody gate, Vector2 position) onDragEnd,
  })  : _position = position,
        _onDragEnd = onDragEnd,
        super(
          children: [
            RectangleComponent(
              size: Vector2(2, 1),
              paint: Paint()..color = AppTheme.primaryColor,
            ),
          ],
        );

  @override
  Body createBody() {
    final bodyDef = BodyDef(
      position: _position,
      type: BodyType.dynamic,
    );

    final body = world.createBody(bodyDef);
    final shape = PolygonShape()..setAsBox(1, 0.5, Vector2.zero(), 0);
    final fixtureDef = FixtureDef(shape);
    body.createFixture(fixtureDef);

    return body;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _onDragEnd(this, position);
    return true;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw gate symbol based on type
    final symbol = _getGateSymbol();
    final textSpan = TextSpan(
      text: symbol,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 0.8,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
  }

  String _getGateSymbol() {
    switch (gateType) {
      case GateType.AND:
        return '&';
      case GateType.OR:
        return '≥1';
      case GateType.NOT:
        return '!';
    }
  }
}

class Wire extends Component {
  final Vector2 start;
  final Vector2 end;
  bool isEnergized = false;

  Wire({required this.start, required this.end});

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color =
          isEnergized ? AppTheme.correctAnswerColor : AppTheme.primaryColor
      ..strokeWidth = 0.1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      start.toOffset(),
      end.toOffset(),
      paint,
    );
  }
}

class InputNode extends PositionComponent {
  bool isActive = false;

  InputNode(Vector2 position) {
    this.position = position;
    size = Vector2(1, 1);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      0.5,
      Paint()
        ..color =
            isActive ? AppTheme.correctAnswerColor : AppTheme.primaryColor,
    );
  }
}

class OutputNode extends PositionComponent {
  bool isActive = false;

  OutputNode(Vector2 position) {
    this.position = position;
    size = Vector2(1, 1);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      0.5,
      Paint()
        ..color =
            isActive ? AppTheme.correctAnswerColor : AppTheme.primaryColor,
    );
  }
}
