import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfBuilder {
  static Future<Uint8List> fromPdfBytes(Uint8List pdfBytes) async {
    // rasterize PDF to image for thermal printer
    final pages = await Printing.raster(pdfBytes, dpi: 203).toList();

    final doc = pw.Document();

    for (final page in pages) {
      final image = pw.MemoryImage(await page.toPng());
      doc.addPage(
        pw.Page(
          build: (_) => pw.Center(child: pw.Image(image)),
        ),
      );
    }

    return doc.save();
  }
}
