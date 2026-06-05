import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Side-effecting actions on the verified rent receipt (EPIC-07 T-013), reusing
/// the EPIC-05 T-008 PDF share/download seam: send the receipt to the tenant via
/// the OS share sheet (WhatsApp / etc.) and save/print it.
///
/// Defined as an interface with a real implementation so the receipt screen can
/// be widget-tested with a fake — the real one calls platform plugins
/// (share_plus, printing) that are unavailable in a headless test.
abstract class ReceiptSharer {
  /// Opens the OS share sheet for the receipt PDF [bytes] (WhatsApp / system
  /// share), writing them to a temp file named after [fileName] first.
  Future<void> sharePdf({required Uint8List bytes, required String fileName});

  /// Opens the OS share sheet with a plain-[text] receipt summary — the fallback
  /// when no receipt PDF is available (e.g. the signed URL hasn't been wired yet).
  Future<void> shareText({required String text, String? subject});

  /// Hands the receipt PDF [bytes] to the platform's print/save flow (download).
  /// On device this surfaces the OS "save to Files / print" sheet.
  Future<void> downloadPdf({required Uint8List bytes, required String fileName});
}

/// Real [ReceiptSharer] backed by share_plus + printing.
class PluginReceiptSharer implements ReceiptSharer {
  const PluginReceiptSharer();

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: fileName, mimeType: _pdfMime)],
        fileNameOverrides: [fileName],
        subject: fileName,
      ),
    );
  }

  @override
  Future<void> shareText({required String text, String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(text: text, subject: subject),
    );
  }

  @override
  Future<void> downloadPdf({
    required Uint8List bytes,
    required String fileName,
  }) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);

  static const String _pdfMime = 'application/pdf';
}

/// The app-wide [ReceiptSharer]; overridden with a fake in widget tests.
final receiptSharerProvider = Provider<ReceiptSharer>(
  (ref) => const PluginReceiptSharer(),
);
