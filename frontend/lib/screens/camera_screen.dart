import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';
import 'market_analysis_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Interpreter? _modelFilter;
  Interpreter? _modelRipeness;
  Interpreter? _modelCondition;

  bool _isAnalyzing = false;
  bool _modelsLoaded = false;
  bool _flashOn = false;
  int _selectedCameraIdx = 0;
  late AnimationController _laserAnimController;

  // Model loading state tracking
  String _loadingStatus = "Initializing...";
  int _modelsLoadedCount = 0;
  bool _loadingError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModels();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    _controller = CameraController(
      cameras[_selectedCameraIdx],
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<Interpreter> _loadInterpreter(
    String assetPath,
    String modelName,
  ) async {
    setState(() {
      _loadingStatus = "Loading $modelName...";
      _loadingError = false;
    });

    final options = InterpreterOptions()..threads = 4;
    try {
      final rawAsset = await rootBundle.load(assetPath);
      final modelBytes = rawAsset.buffer.asUint8List();
      return Interpreter.fromBuffer(modelBytes, options: options);
    } catch (e) {
      throw Exception('Failed to load $modelName model: $e');
    } finally {
      options.delete();
    }
  }

  Future<void> _loadModels() async {
    try {
      _modelFilter = await _loadInterpreter(
        'assets/models/mango_model1_quantized.tflite',
        'Detection',
      );
      setState(() => _modelsLoadedCount = 1);
      await Future.delayed(const Duration(milliseconds: 300));

      _modelRipeness = await _loadInterpreter(
        'assets/models/mango_model2_quantized.tflite',
        'Ripeness',
      );
      setState(() => _modelsLoadedCount = 2);
      await Future.delayed(const Duration(milliseconds: 300));

      _modelCondition = await _loadInterpreter(
        'assets/models/mango_model3_quantized.tflite',
        'Health',
      );
      setState(() => _modelsLoadedCount = 3);
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _loadingStatus = "Ready to Scan!";
        _modelsLoaded = true;
      });
    } catch (e) {
      debugPrint("Error loading models: $e");
      setState(() {
        _loadingError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _loadingStatus = "Failed to load models";
      });
    }
  }

  Future<void> _retryLoadModels() async {
    setState(() {
      _modelsLoaded = false;
      _loadingError = false;
      _modelsLoadedCount = 0;
    });
    await _loadModels();
  }

  void _switchCamera() async {
    HapticFeedback.lightImpact();
    if (cameras.length < 2) return;
    _selectedCameraIdx = _selectedCameraIdx == 0 ? 1 : 0;
    await _controller?.dispose();
    _initCamera();
  }

  void _toggleFlash() async {
    HapticFeedback.lightImpact();
    if (_controller == null) return;
    _flashOn = !_flashOn;
    await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final imgResized = img.copyResize(image, width: 224, height: 224);
    var input = List.generate(
      1,
      (i) => List.generate(
        224,
        (y) => List.generate(224, (x) => List.filled(3, 0.0)),
      ),
    );
    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = imgResized.getPixel(x, y);
        input[0][y][x][0] = pixel.r / 255.0;
        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
      }
    }
    return input;
  }

  Future<void> _saveToHistory(
    String title,
    String date,
    String status,
    String colorHex,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList = prefs.getStringList('mangotrack_history') ?? [];
    Map<String, dynamic> item = {
      'title': title,
      'date': date,
      'status': status,
      'colorHex': colorHex,
    };
    historyList.insert(0, jsonEncode(item));
    if (historyList.length > 20) {
      historyList.removeLast();
    }
    await prefs.setStringList('mangotrack_history', historyList);
  }

  Future<void> _scanImage(String imagePath) async {
    if (!_modelsLoaded) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isAnalyzing = true;
      _laserAnimController.repeat(reverse: true);
    });

    try {
      final File file = File(imagePath);
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) throw Exception("Failed to decode image");

      final input = _preprocessImage(decodedImage);
      await Future.delayed(const Duration(seconds: 1)); // dramatic effect

      var output1 = List.filled(1 * 2, 0.0).reshape([1, 2]);
      _modelFilter!.run(input, output1);
      double isMangoConf = output1[0][0] * 100.0;

      if (isMangoConf < 50.0) {
        HapticFeedback.heavyImpact();
        _showResultDialog(
          "Not a Mango",
          Icons.cancel,
          Colors.red,
          "This doesn't look like a mango. Please try again. (${isMangoConf.toStringAsFixed(1)}% match)",
        );
        _stopAnalyzing();
        return;
      }

      var output2 = List.filled(1 * 2, 0.0).reshape([1, 2]);
      _modelRipeness!.run(input, output2);
      double ripeConf = output2[0][0] * 100.0;

      var output3 = List.filled(1 * 2, 0.0).reshape([1, 2]);
      _modelCondition!.run(input, output3);
      double healthyConf = output3[0][1] * 100.0;

      bool isRipe = ripeConf >= 50;
      bool isHealthy = healthyConf >= 50;

      String title, advice, status, colorHex;
      Color color;

      if (isHealthy) {
        if (isRipe) {
          title = "Ripe & Healthy";
          color = Colors.green;
          status = "Perfect for eating!";
          colorHex = "4CAF50";
          advice =
              "Perfect! This mango is fully ripe, healthy, and ready to eat! \n\nConfidence: ${ripeConf.toStringAsFixed(1)}%";
        } else {
          title = "Unripe but Healthy";
          color = Colors.orange;
          status = "Needs 2-3 days";
          colorHex = "FF9800";
          advice =
              "This mango is healthy but still green. Store it at room temperature. \n\nConfidence: ${(100 - ripeConf).toStringAsFixed(1)}%";
        }
      } else {
        if (isRipe) {
          title = "Ripe but Diseased";
          color = Colors.redAccent;
          status = "Warning";
          colorHex = "FF5252";
          advice =
              "This mango is ripe but shows signs of disease/rot. Consume with caution. \n\nDisease Confidence: ${(100 - healthyConf).toStringAsFixed(1)}%";
        } else {
          title = "Unripe & Diseased";
          color = Colors.red;
          status = "Discard";
          colorHex = "F44336";
          advice =
              "This mango is diseased and unripe. Discarding is recommended. \n\nDisease Confidence: ${(100 - healthyConf).toStringAsFixed(1)}%";
        }
      }

      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      HapticFeedback.mediumImpact();

      // --- CALCULATE READINESS SCORE ---
      double readiness = (ripeConf + healthyConf) / 2;

      String dateStr =
          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}";
      await _saveToHistory(title, dateStr, status, colorHex);

      _showResultDialog(
        title,
        Icons.info_outline,
        color,
        advice,
        readiness: readiness,
      );
    } catch (e) {
      _showResultDialog("Error", Icons.error, Colors.red, e.toString());
    } finally {
      _stopAnalyzing();
    }
  }

  void _stopAnalyzing() {
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _laserAnimController.stop();
        _laserAnimController.reset();
      });
    }
  }

  void _showResultDialog(
    String title,
    IconData icon,
    Color color,
    String message, {
    double readiness = 0.0,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withAlpha(50),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MarketAnalysisScreen(
                        lastScanReadiness: readiness,
                        lastScanTitle: title,
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Market Quality Report",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Scan Another",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _modelFilter?.close();
    _modelRipeness?.close();
    _modelCondition?.close();
    _laserAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "MangoTrack",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Color.fromRGBO(0, 0, 0, 1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _flashOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                            ),
                            onPressed: _toggleFlash,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                            ),
                            onPressed: _switchCamera,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withAlpha(150),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    if (_isAnalyzing)
                      AnimatedBuilder(
                        animation: _laserAnimController,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _laserAnimController.value * 270),
                          child: child,
                        ),
                        child: Container(
                          width: 270,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withAlpha(200),
                                blurRadius: 10,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withAlpha(180),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (!_modelsLoaded)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _loadingError
                                    ? Colors.red.withAlpha(30)
                                    : Colors.orange.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_loadingError)
                                    Column(
                                      children: [
                                        const Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _loadingStatus,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _errorMessage,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        const SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFF59E0B),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _loadingStatus,
                                          style: const TextStyle(
                                            color: Color(0xFFF59E0B),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: _modelsLoadedCount / 3,
                                            backgroundColor: Colors.white12,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                  Color
                                                >(Color(0xFFF59E0B)),
                                            minHeight: 6,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          "$_modelsLoadedCount/3 Models Loaded",
                                          style: const TextStyle(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              icon: _isAnalyzing
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.document_scanner,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                              label: Text(
                                _isAnalyzing
                                    ? "Analyzing AI Data..."
                                    : "Scan Mango",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              onPressed: _isAnalyzing || !_modelsLoaded
                                  ? null
                                  : () async {
                                      final image = await _controller!
                                          .takePicture();
                                      await _scanImage(image.path);
                                    },
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_loadingError)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text(
                                  "Retry Loading Models",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _retryLoadModels,
                              ),
                            )
                          else
                            TextButton.icon(
                              icon: const Icon(
                                Icons.image,
                                color: Colors.white70,
                              ),
                              label: const Text(
                                "Upload from Gallery",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              onPressed: _isAnalyzing || !_modelsLoaded
                                  ? null
                                  : () async {
                                      final picker = ImagePicker();
                                      final XFile? image = await picker
                                          .pickImage(
                                            source: ImageSource.gallery,
                                          );
                                      if (image != null) {
                                        await _scanImage(image.path);
                                      }
                                    },
                            ),
                        ],
                      ),
                    ),
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
