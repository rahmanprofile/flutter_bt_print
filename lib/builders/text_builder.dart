import 'dart:typed_data';
import 'dart:convert';

class TextBuilder {
  static Uint8List build(
      String text, {
        bool bold = false,
        bool center = false,
      }) {
    final buffer = BytesBuilder();

    if (center) buffer.add([0x1B, 0x61, 0x01]); // align center
    if (bold) buffer.add([0x1B, 0x45, 0x01]);   // bold on

    buffer.add(utf8.encode(text));
    buffer.add([0x0A]); // newline

    buffer.add([0x1B, 0x45, 0x00]); // bold off
    buffer.add([0x1B, 0x61, 0x00]); // align left

    return buffer.toBytes();
  }
}
