import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../l10n/app_localizations.dart';

/// Pinch/pan-to-crop, no third-party plugin — the standard `image_cropper`
/// package has no Windows desktop implementation, and this screen is used
/// from the till (Windows) as much as from a phone. Renders exactly what's
/// visible in the fixed square viewport via a [RepaintBoundary] snapshot.
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({
    super.key,
    required this.imageBytes,
    this.circleCrop = false,
  });
  final Uint8List imageBytes;

  /// Shows a circular guide (avatars) instead of a rule-of-thirds grid
  /// (menu items). Purely a visual aid — the exported PNG is always a
  /// square; callers that want a round avatar clip it on display.
  final bool circleCrop;

  @override
  State<ImageCropScreen> createState() => _ImageCropScreenState();
}

class _ImageCropScreenState extends State<ImageCropScreen> {
  static const _outputPx = 320.0;

  final _boundaryKey = GlobalKey();
  final _controller = TransformationController();
  bool _saving = false;
  bool _centered = false;
  double? _imgW;
  double? _imgH;
  int _quarterTurns = 0;
  bool _flipH = false;
  bool _flipV = false;

  double get _effW => _quarterTurns.isOdd ? _imgH! : _imgW!;
  double get _effH => _quarterTurns.isOdd ? _imgW! : _imgH!;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() {
      _imgW = frame.image.width.toDouble();
      _imgH = frame.image.height.toDouble();
    });
  }

  // Scale so the image's shorter side fills the frame (cover-style starting
  // crop), then center it.
  void _centerImage(double side) {
    final scale = side / (_effW < _effH ? _effW : _effH);
    final dx = (side - _effW * scale) / 2;
    final dy = (side - _effH * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
    _centered = true;
  }

  void _rotate() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _centered = false;
    });
  }

  void _zoomBy(double factor, double side) {
    final c = side / 2;
    final zoom = Matrix4.identity()
      ..translateByDouble(c, c, 0, 1)
      ..scaleByDouble(factor, factor, factor, 1)
      ..translateByDouble(-c, -c, 0, 1);
    _controller.value = zoom * _controller.value;
  }

  Future<void> _confirm(double side) async {
    setState(() => _saving = true);
    try {
      final boundary =
          _boundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _outputPx / side);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (mounted) Navigator.of(context).pop(byteData!.buffer.asUint8List());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Fills most of the screen instead of a small fixed square — a Windows
    // window is much bigger than a phone, so this scales with it.
    final side = (MediaQuery.sizeOf(context).shortestSide * 0.8).clamp(
      240.0,
      480.0,
    );
    if (_imgW != null && !_centered) _centerImage(side);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.cropImageTitle),
        actions: [
          TextButton.icon(
            onPressed: (_saving || _imgW == null) ? null : () => _confirm(side),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.white, size: 18),
            label: Text(
              l10n.cropConfirmButton,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _imgW == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Stack(
                      children: [
                        Listener(
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent) {
                              _zoomBy(
                                event.scrollDelta.dy > 0 ? 0.9 : 1.1,
                                side,
                              );
                            }
                          },
                          child: RepaintBoundary(
                            key: _boundaryKey,
                            child: ClipRect(
                              child: InteractiveViewer(
                                transformationController: _controller,
                                constrained: false,
                                minScale: 0.1,
                                maxScale: 5,
                                boundaryMargin: const EdgeInsets.all(
                                  double.infinity,
                                ),
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(
                                    _flipH ? -1.0 : 1.0,
                                    _flipV ? -1.0 : 1.0,
                                    1.0,
                                  ),
                                  child: RotatedBox(
                                    quarterTurns: _quarterTurns,
                                    child: Image.memory(widget.imageBytes),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: CustomPaint(
                            size: Size(side, side),
                            painter: widget.circleCrop
                                ? _CircleGuidePainter()
                                : _CropGridPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.cropResetTooltip,
                        color: Colors.white,
                        icon: const Icon(Icons.refresh),
                        onPressed: () => setState(() => _centerImage(side)),
                      ),
                      IconButton(
                        tooltip: l10n.cropRotateTooltip,
                        color: Colors.white,
                        icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
                        onPressed: _rotate,
                      ),
                      IconButton(
                        tooltip: l10n.cropFlipHorizontalTooltip,
                        color: Colors.white,
                        icon: const Icon(Icons.flip),
                        onPressed: () => setState(() => _flipH = !_flipH),
                      ),
                      IconButton(
                        tooltip: l10n.cropFlipVerticalTooltip,
                        color: Colors.white,
                        icon: const RotatedBox(
                          quarterTurns: 1,
                          child: Icon(Icons.flip),
                        ),
                        onPressed: () => setState(() => _flipV = !_flipV),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.cropHintText,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Rule-of-thirds guide lines drawn over the crop frame — purely a visual
/// aid, drawn outside the [RepaintBoundary] so it never ends up baked into
/// the exported crop.
class _CropGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    for (final f in [1 / 3, 2 / 3]) {
      canvas.drawLine(
        Offset(size.width * f, 0),
        Offset(size.width * f, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * f),
        Offset(size.width, size.height * f),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dims the four corners outside the inscribed circle and draws its
/// outline, so avatar crops preview how they'll actually render once
/// clipped to a circle on display. The exported PNG stays a full square —
/// this is a guide only, drawn outside the [RepaintBoundary].
class _CircleGuidePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect);
    final corners = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect),
      circle,
    );
    canvas.drawPath(corners, Paint()..color = Colors.black.withValues(alpha: 0.5));
    canvas.drawPath(
      circle,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
