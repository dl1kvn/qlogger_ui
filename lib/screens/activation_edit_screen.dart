import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../controllers/database_controller.dart';
import '../data/models/activation_model.dart';
import '../data/models/activation_image_model.dart';

/// Processes thumbnail image in isolate - resizes to max 200px and encodes as PNG
Uint8List? _processThumbnailImage(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;

  img.Image resized;
  if (image.width > image.height) {
    resized = img.copyResize(image, width: 200);
  } else {
    resized = img.copyResize(image, height: 200);
  }

  return Uint8List.fromList(img.encodePng(resized));
}

/// Processes gallery image in isolate - resizes to max 1800px and encodes as JPEG
Uint8List? _processGalleryImage(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return null;

  img.Image resized;
  if (image.width > 1800 || image.height > 1800) {
    if (image.width > image.height) {
      resized = img.copyResize(image, width: 1800);
    } else {
      resized = img.copyResize(image, height: 1800);
    }
  } else {
    resized = image;
  }

  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

class ActivationEditScreen extends StatefulWidget {
  final ActivationModel activation;

  const ActivationEditScreen({super.key, required this.activation});

  @override
  State<ActivationEditScreen> createState() => _ActivationEditScreenState();
}

class _ActivationEditScreenState extends State<ActivationEditScreen> {
  late String _selectedType;
  late TextEditingController _referenceController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _contestIdController;
  String? _imagePath;
  final _dbController = Get.find<DatabaseController>();
  final _imagePicker = ImagePicker();
  List<ActivationImageModel> _galleryImages = [];
  bool _isLoadingImages = false;
  bool _isProcessingImages = false;
  int _processingCount = 0;
  int _processedCount = 0;
  static const int _maxGalleryImages = 10;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.activation.type;
    _referenceController = TextEditingController(text: widget.activation.reference);
    _titleController = TextEditingController(text: widget.activation.title);
    _descriptionController = TextEditingController(text: widget.activation.description);
    _contestIdController = TextEditingController(text: widget.activation.contestId);
    _imagePath = widget.activation.imagePath;
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    if (widget.activation.id == null) return;
    setState(() => _isLoadingImages = true);
    final images = await _dbController.getActivationImages(widget.activation.id!);
    setState(() {
      _galleryImages = images;
      _isLoadingImages = false;
    });
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _contestIdController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'activation_${widget.activation.id ?? DateTime.now().millisecondsSinceEpoch}.png';
      final destPath = p.join(appDir.path, fileName);

      // Read and resize image in isolate
      final bytes = await File(sourcePath).readAsBytes();
      final pngBytes = await compute(_processThumbnailImage, bytes);

      if (pngBytes != null) {
        final destFile = File(destPath);
        await destFile.writeAsBytes(pngBytes);

        setState(() {
          _imagePath = destFile.path;
        });
      }
    }
  }

  Future<void> _removeImage() async {
    if (_imagePath != null) {
      final file = File(_imagePath!);
      if (await file.exists()) {
        await file.delete();
      }
      setState(() {
        _imagePath = null;
      });
    }
  }

  Future<void> _addGalleryImageFromCamera() async {
    if (_galleryImages.length >= _maxGalleryImages) {
      Get.snackbar('Limit Reached', 'Maximum $_maxGalleryImages images allowed',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _isProcessingImages = true;
        _processingCount = 1;
        _processedCount = 0;
      });
      await _saveGalleryImage(photo.path);
      setState(() {
        _isProcessingImages = false;
      });
    }
  }

  Future<void> _addGalleryImageFromGallery() async {
    if (_galleryImages.length >= _maxGalleryImages) {
      Get.snackbar('Limit Reached', 'Maximum $_maxGalleryImages images allowed',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final remaining = _maxGalleryImages - _galleryImages.length;
      final filesToAdd = result.files.take(remaining).toList();

      setState(() {
        _isProcessingImages = true;
        _processingCount = filesToAdd.length;
        _processedCount = 0;
      });

      for (final file in filesToAdd) {
        if (file.path != null) {
          await _saveGalleryImage(file.path!);
          setState(() {
            _processedCount++;
          });
        }
      }

      setState(() {
        _isProcessingImages = false;
      });
    }
  }

  Future<void> _saveGalleryImage(String sourcePath) async {
    if (widget.activation.id == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'gallery_${widget.activation.id}_$timestamp.jpg';
    final destPath = p.join(appDir.path, fileName);

    // Read and resize image in isolate
    final bytes = await File(sourcePath).readAsBytes();
    final jpgBytes = await compute(_processGalleryImage, bytes);

    if (jpgBytes != null) {
      final destFile = File(destPath);
      await destFile.writeAsBytes(jpgBytes);

      // Save to database
      final newImage = ActivationImageModel(
        activationId: widget.activation.id!,
        imagePath: destFile.path,
        sortOrder: _galleryImages.length,
      );
      final savedImage = await _dbController.addActivationImage(newImage);
      if (savedImage != null) {
        setState(() {
          _galleryImages.add(savedImage);
        });
      }
    }
  }

  Future<void> _removeGalleryImage(ActivationImageModel image) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Image', style: TextStyle(fontSize: 16)),
        content: const Text('Remove this image from the gallery?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back(result: true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Delete file
      final file = File(image.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Delete from database
      await _dbController.deleteActivationImage(image.id!);
      setState(() {
        _galleryImages.removeWhere((i) => i.id == image.id);
      });
    }
  }

  Future<void> _save() async {
    final updated = widget.activation.copyWith(
      type: _selectedType,
      reference: _referenceController.text.toUpperCase(),
      title: _titleController.text,
      description: _descriptionController.text,
      imagePath: _imagePath,
      contestId: _contestIdController.text.toUpperCase(),
    );
    await _dbController.updateActivation(updated);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Activation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
              ),
              items: ActivationModel.activationTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(ActivationModel.getIcon(type), size: 20, color: ActivationModel.getColor(type)),
                      const SizedBox(width: 8),
                      Text(type.toUpperCase()),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference',
                hintText: 'e.g. K-1234',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title (max 25 chars)',
                hintText: 'e.g. Central Park',
                counterText: '',
              ),
              maxLength: 25,
              inputFormatters: [
                LengthLimitingTextInputFormatter(25),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (max 150 chars)',
                hintText: 'e.g. Beautiful park in Manhattan',
              ),
              maxLength: 150,
              maxLines: 3,
              inputFormatters: [
                LengthLimitingTextInputFormatter(150),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contestIdController,
              decoration: const InputDecoration(
                labelText: 'Contest ID',
                hintText: 'e.g. CQWW-CW',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_imagePath != null ? 'Change Thumbnail' : 'Add Thumbnail'),
                  ),
                ),
                if (_imagePath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _removeImage,
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ],
            ),
            if (_imagePath != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_imagePath!),
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text('Image not found'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            // Gallery Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gallery (${_galleryImages.length}/$_maxGalleryImages)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _isProcessingImages || _galleryImages.length >= _maxGalleryImages
                          ? null
                          : _addGalleryImageFromCamera,
                      icon: const Icon(Icons.camera_alt),
                      tooltip: 'Take Photo',
                    ),
                    IconButton(
                      onPressed: _isProcessingImages || _galleryImages.length >= _maxGalleryImages
                          ? null
                          : _addGalleryImageFromGallery,
                      icon: const Icon(Icons.photo_library),
                      tooltip: 'Choose from Gallery',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isProcessingImages)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Processing $_processedCount / $_processingCount...',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            if (_isLoadingImages)
              const Center(child: CircularProgressIndicator())
            else if (!_isProcessingImages && _galleryImages.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No gallery images yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final image = _galleryImages[index];
                  return Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(image.imagePath),
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 150,
                              color: Colors.grey.shade300,
                              child: const Center(child: Text('Image not found')),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 18),
                            onPressed: () => _removeGalleryImage(image),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
