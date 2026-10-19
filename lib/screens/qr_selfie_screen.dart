import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/attendance_service.dart';

class QrSelfieScreen extends StatefulWidget {
  final String attendanceType; // 'CHECK_IN' və ya 'CHECK_OUT'
  const QrSelfieScreen({super.key, required this.attendanceType});

  @override
  State<QrSelfieScreen> createState() => _QrSelfieScreenState();
}

class _QrSelfieScreenState extends State<QrSelfieScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );
  CameraController? _frontCameraController;
  bool _isProcessing = false;
  String _statusMessage = "Zəhmət olmasa qapıdakı QR kodu oxudun";

  @override
  void initState() {
    super.initState();
    // Do not open the front camera yet. MobileScanner uses the rear camera;
    // opening both camera controllers at once can fail on many Android phones.
  }

  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _frontCameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _frontCameraController!.initialize();
    } catch (e) {
      debugPrint("Ön kamera başladılarkən: $e");
    }
  }

  Future<void> _onBarcodeScanned(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "QR təsdiqləndi! Təsdiq selfie-si çəkilir...";
    });

    await _scannerController.stop();

    try {
      // Release the QR camera before requesting the front camera for the selfie.
      await _initFrontCamera();
      File? selfieFile;
      if (_frontCameraController != null && _frontCameraController!.value.isInitialized) {
        final XFile photo = await _frontCameraController!.takePicture();
        selfieFile = File(photo.path);
      }

      setState(() {
        _statusMessage = "Növbə qeydiyyatı bazaya ötürülür...";
      });

      final currentUser = Firebase.apps.isNotEmpty ? FirebaseAuth.instance.currentUser : null;
      await AttendanceService().recordAttendance(
        workerId: currentUser?.uid ?? 'WORKER_DEMO_1042',
        workerName: currentUser?.displayName ?? "İşçi Əməkdaş",
        type: widget.attendanceType,
        selfieFile: selfieFile,
        qrPayload: qrData,
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xəta: $e"), backgroundColor: Colors.red),
        );
        setState(() {
          _isProcessing = false;
          _statusMessage = "Zəhmət olmasa qapıdakı QR kodu oxudun";
        });
        _scannerController.start();
      }
    }
  }

  void _showSuccessDialog() {
    final isCheckIn = widget.attendanceType == 'CHECK_IN';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          color: isCheckIn ? Colors.green : Colors.orange,
          size: 64,
        ),
        title: Text(isCheckIn ? "Giriş Təsdiqləndi!" : "Çıxış Təsdiqləndi!"),
        content: Text(
          isCheckIn
              ? "Vardiya girişiniz və selfie şəkliniz qeydə alındı. Uğurlu işlər!"
              : "Vardiya çıxışınız qeydə alındı. Yaxşı istirahətlər!",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Oldu"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _frontCameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.attendanceType == 'CHECK_IN' ? "Kluba Giriş (QR)" : "Klubdan Çıxış (QR)"),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeScanned,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isProcessing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      else
                        const Icon(Icons.qr_code_scanner, color: Colors.amber),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent, width: 3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    "Təhlükəsizlik qaydası: QR oxunan anda şəxsiyyət təsdiqi üçün selfie çəkilir.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
