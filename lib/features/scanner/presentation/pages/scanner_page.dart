import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../product/presentation/bloc/product_bloc.dart';
import '../../../product/presentation/bloc/product_event.dart';
import '../../../product/presentation/pages/product_result_page.dart';
import '../bloc/scanner_bloc.dart';
import '../bloc/scanner_event.dart';
import '../bloc/scanner_state.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    setState(() {
      _isInitialized = true;
    });
    context.read<ScannerBloc>().add(const StartScanningEvent());
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          BlocBuilder<ScannerBloc, ScannerState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(
                  state.isFlashOn ? Icons.flash_on : Icons.flash_off,
                ),
                onPressed: () {
                  _controller?.toggleTorch();
                  context.read<ScannerBloc>().add(const ToggleFlashEvent());
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () {
              _controller?.switchCamera();
              context.read<ScannerBloc>().add(const SwitchCameraEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<ScannerBloc, ScannerState>(
        listener: (context, state) {
          if (state.status == ScannerStatus.barcodeDetected &&
              state.detectedBarcode != null) {
            // Fetch product info
            context.read<ProductBloc>().add(
                  FetchProductEvent(barcode: state.detectedBarcode!),
                );

            // Navigate to result page
            // ignore: use_build_context_synchronously
            final navigator = Navigator.of(context);
            final bloc = context.read<ScannerBloc>();
            navigator.push(
              MaterialPageRoute(
                builder: (_) => ProductResultPage(
                  barcode: state.detectedBarcode!,
                ),
              ),
            ).then((_) {
              // Reset scanner when returning
              bloc.add(const ResetScannerEvent());
            });
          }
        },
        builder: (context, state) {
          if (!_isInitialized || _controller == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            children: [
              // Camera View
              MobileScanner(
                controller: _controller!,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty &&
                      state.status != ScannerStatus.barcodeDetected) {
                    final barcode = barcodes.first;
                    if (barcode.rawValue != null) {
                      context.read<ScannerBloc>().add(
                            BarcodeDetectedEvent(
                              barcode: barcode.rawValue!,
                              format: barcode.format.name,
                            ),
                          );
                    }
                  }
                },
              ),

              // Scan Overlay
              _ScanOverlay(),

              // Instructions
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      state.status == ScannerStatus.barcodeDetected
                          ? 'Barcode detected!'
                          : 'Point camera at a barcode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Manual Entry Button
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => _showManualEntryDialog(context),
                    icon: const Icon(Icons.keyboard),
                    label: const Text('Enter barcode manually'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showManualEntryDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'e.g., 5000112558067',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final barcode = controller.text.trim();
              if (barcode.isNotEmpty) {
                Navigator.pop(dialogContext);
                context.read<ScannerBloc>().add(
                      BarcodeDetectedEvent(barcode: barcode),
                    );
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.7;
        final left = (constraints.maxWidth - scanAreaSize) / 2;
        final top = (constraints.maxHeight - scanAreaSize) / 2;

        return Stack(
          children: [
            // Dark overlay with transparent center
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Corner decorations
            Positioned(
              left: left,
              top: top,
              child: const _ScanCorner(corner: _Corner.topLeft),
            ),
            Positioned(
              right: left,
              top: top,
              child: const _ScanCorner(corner: _Corner.topRight),
            ),
            Positioned(
              left: left,
              bottom: top,
              child: const _ScanCorner(corner: _Corner.bottomLeft),
            ),
            Positioned(
              right: left,
              bottom: top,
              child: const _ScanCorner(corner: _Corner.bottomRight),
            ),
          ],
        );
      },
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _ScanCorner extends StatelessWidget {
  final _Corner corner;
  final double size = 24;
  final double strokeWidth = 4;

  const _ScanCorner({required this.corner});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerPainter(
        corner: corner,
        strokeWidth: strokeWidth,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final _Corner corner;
  final double strokeWidth;
  final Color color;

  _CornerPainter({
    required this.corner,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    switch (corner) {
      case _Corner.topLeft:
        path.moveTo(0, size.height);
        path.lineTo(0, 0);
        path.lineTo(size.width, 0);
        break;
      case _Corner.topRight:
        path.moveTo(0, 0);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
        break;
      case _Corner.bottomLeft:
        path.moveTo(0, 0);
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
        break;
      case _Corner.bottomRight:
        path.moveTo(size.width, 0);
        path.lineTo(size.width, size.height);
        path.lineTo(0, size.height);
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}