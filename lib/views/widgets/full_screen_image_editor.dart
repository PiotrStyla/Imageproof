import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/models/image_proof.dart';
import 'package:image/image.dart' as img;

class FullScreenImageEditor extends StatefulWidget {
  final Uint8List image;
  final TransformationType? activeSelectionType;
  final Function(ImageTransformation) onTransformationAdded;
  final Function(TransformationType?) onSelectionTypeChanged;

  const FullScreenImageEditor({
    super.key,
    required this.image,
    required this.activeSelectionType,
    required this.onTransformationAdded,
    required this.onSelectionTypeChanged,
  });

  @override
  State<FullScreenImageEditor> createState() => _FullScreenImageEditorState();
}

class _FullScreenImageEditorState extends State<FullScreenImageEditor> {
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _imageKey = GlobalKey();
  double _currentZoom = 1.0;
  Offset? _selectionStart;
  Offset? _selectionEnd;
  TransformationType? _activeSelectionType;

  @override
  void initState() {
    super.initState();
    _activeSelectionType = widget.activeSelectionType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full viewport image editor
          Center(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 10.0,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              panEnabled:
                  _activeSelectionType == null, // Disable pan when selecting
              scaleEnabled:
                  _activeSelectionType ==
                  null, // Disable zoom gestures when selecting
              onInteractionUpdate: (details) {
                setState(() {
                  _currentZoom =
                      _transformationController.value.getMaxScaleOnAxis();
                });
              },
              child:
                  _activeSelectionType != null
                      ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          final RenderBox? box =
                              _imageKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (box != null) {
                            final offset = box.globalToLocal(
                              details.globalPosition,
                            );
                            setState(() {
                              _selectionStart = offset;
                              _selectionEnd = offset;
                            });
                          }
                        },
                        onPanUpdate: (details) {
                          final RenderBox? box =
                              _imageKey.currentContext?.findRenderObject()
                                  as RenderBox?;
                          if (box != null) {
                            final offset = box.globalToLocal(
                              details.globalPosition,
                            );
                            setState(() {
                              _selectionEnd = offset;
                            });
                          }
                        },
                        onPanEnd: (details) {
                          _createTransformationFromSelection();
                        },
                        child: Stack(
                          children: [
                            Image.memory(
                              key: _imageKey,
                              widget.image,
                              fit: BoxFit.contain,
                            ),
                            if (_selectionStart != null &&
                                _selectionEnd != null)
                              CustomPaint(
                                painter: _SelectionPainter(
                                  start: _selectionStart!,
                                  end: _selectionEnd!,
                                  color: _getSelectionColor(),
                                ),
                              ),
                          ],
                        ),
                      )
                      : Stack(
                        children: [
                          Image.memory(
                            key: _imageKey,
                            widget.image,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
            ),
          ),

          // Top toolbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close Editor',
                  ),
                  const Spacer(),
                  Text(
                    'Full Screen Editor',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(_currentZoom * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right side zoom controls
          Positioned(
            top: 100,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    tooltip: 'Zoom In',
                    onPressed: () {
                      final newScale = (_currentZoom * 1.5).clamp(1.0, 10.0);
                      _transformationController.value =
                          Matrix4.identity()..scale(newScale);
                      setState(() => _currentZoom = newScale);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.white),
                    tooltip: 'Zoom Out',
                    onPressed: () {
                      final newScale = (_currentZoom / 1.5).clamp(1.0, 10.0);
                      _transformationController.value =
                          Matrix4.identity()..scale(newScale);
                      setState(() => _currentZoom = newScale);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.fit_screen, color: Colors.white),
                    tooltip: 'Reset Zoom',
                    onPressed: () {
                      _transformationController.value = Matrix4.identity();
                      setState(() => _currentZoom = 1.0);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom toolbar with transformation tools
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child:
                  _activeSelectionType != null
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.touch_app,
                            color: _getSelectionColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Drag to select region • Scroll to zoom up to 1000%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectionStart = null;
                                _selectionEnd = null;
                                _activeSelectionType = null;
                              });
                              widget.onSelectionTypeChanged(null);
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      )
                      : Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: [
                          _buildToolButton(
                            'Blur Region',
                            Icons.blur_on,
                            Colors.red,
                            TransformationType.blurRegion,
                          ),
                          _buildToolButton(
                            'Redact',
                            Icons.block,
                            Colors.black,
                            TransformationType.redactRegion,
                          ),
                          _buildToolButton(
                            'Pixelate',
                            Icons.grid_on,
                            Colors.deepOrange,
                            TransformationType.pixelateRegion,
                          ),
                        ],
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    String label,
    IconData icon,
    Color color,
    TransformationType type,
  ) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _activeSelectionType = type;
        });
        widget.onSelectionTypeChanged(type);
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getSelectionColor() {
    switch (_activeSelectionType) {
      case TransformationType.blurRegion:
        return Colors.red;
      case TransformationType.redactRegion:
        return Colors.black;
      case TransformationType.pixelateRegion:
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  void _createTransformationFromSelection() {
    if (_selectionStart == null ||
        _selectionEnd == null ||
        _activeSelectionType == null) {
      return;
    }

    final RenderBox? renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final imageSize = renderBox.size;

    final matrix = _transformationController.value;
    final inverseMatrix = Matrix4.inverted(matrix);

    final transformedStart = MatrixUtils.transformPoint(
      inverseMatrix,
      _selectionStart!,
    );
    final transformedEnd = MatrixUtils.transformPoint(
      inverseMatrix,
      _selectionEnd!,
    );

    final left = transformedStart.dx.clamp(0.0, imageSize.width);
    final top = transformedStart.dy.clamp(0.0, imageSize.height);
    final right = transformedEnd.dx.clamp(0.0, imageSize.width);
    final bottom = transformedEnd.dy.clamp(0.0, imageSize.height);

    final x = left < right ? left : right;
    final y = top < bottom ? top : bottom;
    final width = (left - right).abs();
    final height = (top - bottom).abs();

    if (width < 10 || height < 10) {
      setState(() {
        _selectionStart = null;
        _selectionEnd = null;
      });
      return;
    }

    final img.Image? decodedImage = img.decodeImage(widget.image);
    if (decodedImage == null) return;

    final scaleX = decodedImage.width / imageSize.width;
    final scaleY = decodedImage.height / imageSize.height;

    final actualX = (x * scaleX).round();
    final actualY = (y * scaleY).round();
    final actualWidth = (width * scaleX).round();
    final actualHeight = (height * scaleY).round();

    Map<String, dynamic> params;
    switch (_activeSelectionType!) {
      case TransformationType.blurRegion:
        params = {
          'x': actualX,
          'y': actualY,
          'width': actualWidth,
          'height': actualHeight,
          'radius': 15,
        };
        break;
      case TransformationType.redactRegion:
        params = {
          'x': actualX,
          'y': actualY,
          'width': actualWidth,
          'height': actualHeight,
        };
        break;
      case TransformationType.pixelateRegion:
        params = {
          'x': actualX,
          'y': actualY,
          'width': actualWidth,
          'height': actualHeight,
          'pixelSize': 20,
        };
        break;
      default:
        return;
    }

    widget.onTransformationAdded(
      ImageTransformation(
        type: _activeSelectionType!,
        parameters: params,
        appliedAt: DateTime.now(),
        isReversible: true,
      ),
    );
  }
}

class _SelectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;

  _SelectionPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromPoints(start, end);
    final paint =
        Paint()
          ..color = color.withAlpha(77)
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawRect(rect, paint);
    canvas.drawRect(rect, borderPaint);
  }

  @override
  bool shouldRepaint(_SelectionPainter oldDelegate) => true;
}
