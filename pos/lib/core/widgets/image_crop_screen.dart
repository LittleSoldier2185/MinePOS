import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../l10n/app_localizations.dart';

/// Pinch/pan-to-crop, no third-party plugin — the standard `image_cropper`
/// package has no Windows desktop implementation, and this screen is used
/// from the till (Windows) as much as from a phone. Renders exactly what's
/// visible in the fixed square viewport via a [RepaintBoundary] snapshot.
class ImageCropScreen extends StatefulWidget {
  const ImageCropScreen({super.key, required this.imageBytes});
  final Uint8List imageBytes;

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
    final w = _imgW!;
    final h = _imgH!;
    final scale = side / (w < h ? w : h);
    final dx = (side - w * scale) / 2;
    final dy = (side - h * scale) / 2;
    _controller.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(scale, scale, scale, 1);
    _centered = true;
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
                        RepaintBoundary(
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
                              child: Image.memory(widget.imageBytes),
                            ),
                          ),
                        ),
                        IgnorePointer(
                          child: CustomPaint(
                            size: Size(side, side),
                            painter: _CropGridPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
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
