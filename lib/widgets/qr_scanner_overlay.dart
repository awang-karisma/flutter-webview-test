import 'package:flutter/material.dart';

/// Animated QR-style scanner overlay with scanning line and corner brackets.
///
/// This widget displays a square viewfinder with:
/// - Dark overlay outside the viewfinder area
/// - Four animated corner brackets
/// - Horizontal scanning line that moves vertically
class QRScannerOverlay extends StatefulWidget {
  /// Size of the viewfinder (width and height, it's square)
  final double viewfinderSize;

  /// Color of the scanning line
  final Color scanLineColor;

  /// Color of the corner brackets
  final Color bracketColor;

  /// Color of the overlay outside the viewfinder
  final Color overlayColor;

  /// Thickness of the corner brackets
  final double bracketThickness;

  /// Length of each bracket side
  final double bracketLength;

  /// Duration of the scanning line animation
  final Duration scanAnimationDuration;

  /// Duration of the bracket pulse animation
  final Duration bracketPulseDuration;

  const QRScannerOverlay({
    super.key,
    this.viewfinderSize = 280,
    this.scanLineColor = const Color(0x802196F3),
    this.bracketColor = const Color(0xFF00E5FF),
    this.overlayColor = const Color(0x99000000),
    this.bracketThickness = 3.0,
    this.bracketLength = 30.0,
    this.scanAnimationDuration = const Duration(seconds: 2),
    this.bracketPulseDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<QRScannerOverlay> createState() => _QRScannerOverlayState();
}

class _QRScannerOverlayState extends State<QRScannerOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late AnimationController _bracketPulseController;
  late Animation<double> _scanAnimation;
  late Animation<double> _bracketPulseAnimation;

  @override
  void initState() {
    super.initState();

    // Scanning line animation (moves top to bottom)
    _scanAnimationController = AnimationController(
      duration: widget.scanAnimationDuration,
      vsync: this,
    )..repeat();

    _scanAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scanAnimationController,
      curve: Curves.linear,
    ));

    // Corner bracket pulse animation (opacity pulse)
    _bracketPulseController = AnimationController(
      duration: widget.bracketPulseDuration,
      vsync: this,
    )..repeat(reverse: true);

    _bracketPulseAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bracketPulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    _bracketPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;

        // Center the viewfinder
        final left = (screenWidth - widget.viewfinderSize) / 2;
        final top = (screenHeight - widget.viewfinderSize) / 2 - 50; // Shift up a bit for button space

        return Stack(
          children: [
            // Custom painter for overlay, viewfinder, and brackets
            AnimatedBuilder(
              animation: Listenable.merge([
                _scanAnimation,
                _bracketPulseAnimation,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  size: Size(screenWidth, screenHeight),
                  painter: _ScannerOverlayPainter(
                    viewfinderRect: Rect.fromLTWH(
                      left,
                      top,
                      widget.viewfinderSize,
                      widget.viewfinderSize,
                    ),
                    overlayColor: widget.overlayColor,
                    bracketColor: widget.bracketColor,
                    bracketThickness: widget.bracketThickness,
                    bracketLength: widget.bracketLength,
                    scanLineColor: widget.scanLineColor,
                    scanLineProgress: _scanAnimation.value,
                    bracketOpacity: _bracketPulseAnimation.value,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Custom painter that draws the scanner overlay elements.
class _ScannerOverlayPainter extends CustomPainter {
  final Rect viewfinderRect;
  final Color overlayColor;
  final Color bracketColor;
  final double bracketThickness;
  final double bracketLength;
  final Color scanLineColor;
  final double scanLineProgress;
  final double bracketOpacity;

  _ScannerOverlayPainter({
    required this.viewfinderRect,
    required this.overlayColor,
    required this.bracketColor,
    required this.bracketThickness,
    required this.bracketLength,
    required this.scanLineColor,
    required this.scanLineProgress,
    required this.bracketOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw dark overlay with transparent viewfinder cutout
    _drawOverlay(canvas, size);

    // Draw corner brackets with animated opacity
    _drawCornerBrackets(canvas);

    // Draw scanning line
    _drawScanLine(canvas);
  }

  void _drawOverlay(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = overlayColor;

    // Draw overlay as path with hole for viewfinder
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        viewfinderRect,
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);
  }

  void _drawCornerBrackets(Canvas canvas) {
    final bracketPaint = Paint()
      ..color = bracketColor.withOpacity(bracketOpacity)
      ..strokeWidth = bracketThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final left = viewfinderRect.left;
    final top = viewfinderRect.top;
    final right = viewfinderRect.right;
    final bottom = viewfinderRect.bottom;
    final length = bracketLength;

    // Top-left corner bracket
    final topLeftPath = Path()
      ..moveTo(left, top + length)
      ..lineTo(left, top)
      ..lineTo(left + length, top);
    canvas.drawPath(topLeftPath, bracketPaint);

    // Top-right corner bracket
    final topRightPath = Path()
      ..moveTo(right - length, top)
      ..lineTo(right, top)
      ..lineTo(right, top + length);
    canvas.drawPath(topRightPath, bracketPaint);

    // Bottom-left corner bracket
    final bottomLeftPath = Path()
      ..moveTo(left, bottom - length)
      ..lineTo(left, bottom)
      ..lineTo(left + length, bottom);
    canvas.drawPath(bottomLeftPath, bracketPaint);

    // Bottom-right corner bracket
    final bottomRightPath = Path()
      ..moveTo(right - length, bottom)
      ..lineTo(right, bottom)
      ..lineTo(right, bottom - length);
    canvas.drawPath(bottomRightPath, bracketPaint);
  }

  void _drawScanLine(Canvas canvas) {
    final scanLineY = viewfinderRect.top +
        (viewfinderRect.height * scanLineProgress);

    final scanLinePaint = Paint()
      ..color = scanLineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal scanning line
    canvas.drawLine(
      Offset(viewfinderRect.left + 10, scanLineY),
      Offset(viewfinderRect.right - 10, scanLineY),
      scanLinePaint,
    );

    // Add gradient effect (glow around the line)
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scanLineColor.withOpacity(0.5),
          scanLineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(
        viewfinderRect.left,
        scanLineY - 10,
        viewfinderRect.width,
        20,
      ));

    canvas.drawRect(
      Rect.fromLTWH(
        viewfinderRect.left + 10,
        scanLineY - 10,
        viewfinderRect.width - 20,
        20,
      ),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return scanLineProgress != oldDelegate.scanLineProgress ||
        bracketOpacity != oldDelegate.bracketOpacity;
  }
}
