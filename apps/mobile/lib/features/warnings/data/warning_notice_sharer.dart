import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Side-effecting actions on the generated warning notice PDF (EPIC-20 T-006):
/// sharing it via the OS sheet (WhatsApp / etc.) and saving/printing it.
///
/// Defined as an interface with a real implementation so the notice screen can
/// be widget-tested with a fake — the real one calls platform plugins
/// (share_plus, printing) that are unavailable in a headless test.
///
/// Mirrors [DmpPdfSharer] from EPIC-05 T-008.
abstract class WarningNoticeSharer {
  /// Opens the OS share sheet for the PDF [bytes] (WhatsApp / system share),
  /// writing them to a temp file named after [fileName] first.
  Future<void> share({required Uint8List bytes, required String fileName});

  /// Hands the PDF [bytes] to the platform's print/save flow (download). On
  /// device this surfaces the OS "save to Files / print" sheet.
  Future<void> download({required Uint8List bytes, required String fileName});
}

/// Real [WarningNoticeSharer] backed by share_plus + printing.
class PluginWarningNoticeSharer implements WarningNoticeSharer {
  const PluginWarningNoticeSharer();

  @override
  Future<void> share({
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
  Future<void> download({
    required Uint8List bytes,
    required String fileName,
  }) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName);

  static const String _pdfMime = 'application/pdf';
}

/// The app-wide [WarningNoticeSharer]; overridden with a fake in widget tests.
final warningNoticeSharerProvider = Provider<WarningNoticeSharer>(
  (ref) => const PluginWarningNoticeSharer(),
);
