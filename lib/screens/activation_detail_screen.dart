import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/database_controller.dart';
import '../data/models/activation_model.dart';
import '../data/models/activation_image_model.dart';

class ActivationDetailScreen extends StatefulWidget {
  final ActivationModel activation;

  const ActivationDetailScreen({super.key, required this.activation});

  @override
  State<ActivationDetailScreen> createState() => _ActivationDetailScreenState();
}

class _ActivationDetailScreenState extends State<ActivationDetailScreen> {
  final _dbController = Get.find<DatabaseController>();
  List<ActivationImageModel> _galleryImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    if (widget.activation.id == null) {
      setState(() => _isLoading = false);
      return;
    }
    final images = await _dbController.getActivationImages(widget.activation.id!);
    setState(() {
      _galleryImages = images;
      _isLoading = false;
    });
  }

  void _openGallerySlider(int initialIndex) {
    Get.to(() => _GallerySliderPage(
          images: _galleryImages,
          initialIndex: initialIndex,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final activation = widget.activation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('${activation.type.toUpperCase()} ${activation.reference}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
              child: Row(
                children: [
                  Icon(
                    ActivationModel.getIcon(activation.type),
                    size: 48,
                    color: ActivationModel.getColor(activation.type),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${activation.type.toUpperCase()} ${activation.reference}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (activation.title.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            activation.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                        if (activation.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            activation.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                        if (activation.contestId.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Contest: ${activation.contestId}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (activation.imagePath != null &&
                      activation.imagePath!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(activation.imagePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Gallery section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Gallery',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_galleryImages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'No gallery images',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _galleryImages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final image = _galleryImages[index];
                  return GestureDetector(
                    onTap: () => _openGallerySlider(index),
                    child: Container(
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

class _GallerySliderPage extends StatefulWidget {
  final List<ActivationImageModel> images;
  final int initialIndex;

  const _GallerySliderPage({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_GallerySliderPage> createState() => _GallerySliderPageState();
}

class _GallerySliderPageState extends State<_GallerySliderPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          final image = widget.images[index];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.file(
                File(image.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text(
                    'Image not found',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.images.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.images.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
