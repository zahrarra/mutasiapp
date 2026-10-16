// lib/core/services/document_picker_web.dart
//
// Implementasi Web HTML file picker via browser input element.
// Digunakan saat aplikasi berjalan di Web browser agar kebal terhadap
// MissingPluginException akibat channel native yang tidak tersedia di Web.

// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

class WebDocumentPicker {
  static Future<Map<String, dynamic>?> pickFileWeb({
    required List<String> allowedExtensions,
  }) async {
    final completer = Completer<Map<String, dynamic>?>();
    final input = html.FileUploadInputElement();
    input.accept = allowedExtensions.map((e) => '.$e').join(',');

    void handleChange(html.Event event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        Uint8List? bytes;
        if (result is Uint8List) {
          bytes = result;
        } else if (result is ByteBuffer) {
          bytes = Uint8List.view(result);
        } else if (result is List<int>) {
          bytes = Uint8List.fromList(result);
        }

        if (!completer.isCompleted) {
          completer.complete({
            'name': file.name,
            'size': file.size,
            'bytes': bytes,
          });
        }
      });

      reader.onError.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      reader.readAsArrayBuffer(file);
    }

    input.onChange.first.then((event) => handleChange(event));

    // Buka dialog file browser
    input.click();

    return completer.future;
  }
}
