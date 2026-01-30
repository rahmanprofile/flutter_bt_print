import 'dart:typed_data';

class ImageBuilder {
  static Uint8List build(Uint8List imageBytes) {
    return imageBytes; // Android side handles bitmap → printer
  }
}
