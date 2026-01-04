import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final image = img.Image(width: size, height: size);

  final white = img.ColorRgba8(255, 255, 255, 255);
  final red = img.ColorRgba8(220, 38, 38, 255);

  // Fill background with white
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      image.setPixel(x, y, white);
    }
  }

  // Draw a simple lowercase "q"
  // Centered in the image
  final centerX = size * 0.45;
  final centerY = size * 0.40;
  final outerRadius = size * 0.26;
  final innerRadius = size * 0.12;
  final strokeWidth = outerRadius - innerRadius;

  // Draw the circular part of q
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final dx = x - centerX;
      final dy = y - centerY;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance <= outerRadius && distance >= innerRadius) {
        image.setPixel(x, y, red);
      }
    }
  }

  // Draw the descender (vertical stem on the right)
  final stemX = centerX + outerRadius - strokeWidth / 2;
  final stemTop = centerY - outerRadius * 0.3;
  final stemBottom = size * 0.78;
  final stemWidth = strokeWidth;

  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      if (x >= stemX - stemWidth / 2 &&
          x <= stemX + stemWidth / 2 &&
          y >= stemTop &&
          y <= stemBottom) {
        image.setPixel(x, y, red);
      }
    }
  }

  // Save the image
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }

  final pngBytes = img.encodePng(image);
  File('assets/app_icon.png').writeAsBytesSync(pngBytes);

  print('Generated app_icon.png');
}
