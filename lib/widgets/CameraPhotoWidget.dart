import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:pocketbase/src/sse/sse_message.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPhotoWidget extends StatefulWidget {
  const CameraPhotoWidget({
    super.key,
    required this.size,
    required this.color,
    required this.width,
    required this.height,
    required this.baseUrl,
    required this.coleccion,
    required this.campoFoto,
    required this.imagenUrl,
    required this.registroId,
    required this.authToken,
  });

  final double size;
  final Color color;
  final double width;
  final double height;
  final String baseUrl;
  final String coleccion;
  final String campoFoto;
  final String imagenUrl;
  final String registroId;
  final String authToken;

  @override
  State<CameraPhotoWidget> createState() => _CameraPhotoWidgetState();
}

class _CameraPhotoWidgetState extends State<CameraPhotoWidget> {
  late PocketBase pb;
  late CameraController _controller;
  bool _isLoading = false;
  String? _photoPath;
  bool _cameraInitialized = false;

  @override
  void initState() {
    super.initState();
    pb = PocketBase(widget.baseUrl);
    _initializeCamera();
    _setupRealtime();
  }

  void _setupRealtime() {
    pb.realtime.subscribe('${widget.coleccion}/${widget.registroId}', (e) {
      if (e.action == 'update') {
        setState(() {});
      }
    });
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      _controller = CameraController(
        cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
        ResolutionPreset.high,
      );
      await _controller.initialize();
      setState(() => _cameraInitialized = true);
    } catch (e) {
      print("Error inicializando cámara: $e");
    }
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      throw Exception('Permiso de cámara denegado');
    }
  }

  Future<void> _takePhoto() async {
    if (!_cameraInitialized || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      await _requestPermissions();
      final XFile photo = await _controller.takePicture();
      _photoPath = photo.path;

      await _uploadPhoto();
      await _updateImageUrl();
    } catch (e) {
      print("Error tomando foto: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadPhoto() async {
    final file = File(_photoPath!);
    final bytes = await file.readAsBytes();
    final filename = 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await pb.collection(widget.coleccion).update(
      widget.registroId,
      files: [
        FileUpload(
          file: bytes,
          field: widget.campoFoto,
          filename: filename,
          contentType: 'image/jpeg',
        ),
      ],
    );
  }

  Future<void> _updateImageUrl() async {
    final record =
        await pb.collection(widget.coleccion).getOne(widget.registroId);
    final fotoUrl =
        pb.getFileUrl(record, record.getDataValue(widget.campoFoto));

    await pb.collection(widget.coleccion).update(
      widget.registroId,
      body: {
        widget.imagenUrl: fotoUrl,
        'updated': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    pb.realtime.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _takePhoto,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: widget.size,
              color: _isLoading ? Colors.grey : widget.color,
            ),
            if (_isLoading)
              CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(widget.color),
              ),
          ],
        ),
      ),
    );
  }

  FileUpload(
      {required Uint8List file,
      required String field,
      required String filename,
      required String contentType}) {}
}

extension on SseMessage {
  get action => null;
}
