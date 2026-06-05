import 'dart:convert';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Side-effecting export of the (scoped + filtered) expenses CSV (EPIC-08
/// T-008 / T-011). The CSV text is fetched server-side via
/// [ExpenseRepository.exportCsv]; this seam only hands it to the OS share sheet
/// (WhatsApp / system share / save to Files).
///
/// Defined as an interface with a real implementation so the expenses screen can
/// be widget-tested with a fake — the real one calls a platform plugin
/// (share_plus) that is unavailable in a headless test.
abstract class ExpenseCsvSharer {
  /// Opens the OS share sheet for the expenses [csv] text, written to a temp
  /// file named after [fileName] so it shares as an attachment rather than a
  /// raw text blob.
  Future<void> shareCsv({required String csv, required String fileName});
}

/// Real [ExpenseCsvSharer] backed by share_plus.
class PluginExpenseCsvSharer implements ExpenseCsvSharer {
  const PluginExpenseCsvSharer();

  @override
  Future<void> shareCsv({
    required String csv,
    required String fileName,
  }) async {
    final Uint8List bytes = Uint8List.fromList(utf8.encode(csv));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: fileName, mimeType: _csvMime)],
        fileNameOverrides: [fileName],
        subject: fileName,
      ),
    );
  }

  static const String _csvMime = 'text/csv';
}

/// The app-wide [ExpenseCsvSharer]; overridden with a fake in widget tests.
final expenseCsvSharerProvider = Provider<ExpenseCsvSharer>(
  (ref) => const PluginExpenseCsvSharer(),
);
