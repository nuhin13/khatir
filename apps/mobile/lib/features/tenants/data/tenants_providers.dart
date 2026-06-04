import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/dio_client.dart';
import 'tenant_repository.dart';

/// The shared [TenantRepository], backed by the app-wide dio client.
final tenantRepositoryProvider = Provider<TenantRepository>(
  (ref) => TenantRepository(ref.watch(dioClientProvider)),
);

/// The bytes + filename of a picked image, decoupled from the picker plugin so
/// the capture screen and its tests do not depend on [XFile] directly.
class PickedImage {
  const PickedImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Picks an NID image from the camera or the gallery. An interface (not a
/// concrete plugin call) so widget tests inject a fake without the
/// platform-channel `image_picker` plugin.
abstract class ImagePickerService {
  /// Captures via the device camera. Returns `null` if the user cancels.
  Future<PickedImage?> pickFromCamera();

  /// Picks from the gallery. Returns `null` if the user cancels.
  Future<PickedImage?> pickFromGallery();
}

/// Default [ImagePickerService] backed by the `image_picker` plugin.
///
/// The picked file is read into memory and handed to the caller for upload; we
/// never copy it into app storage, so nothing lingers on the device after the
/// upload completes (T-010 §15). [maxWidth]/[imageQuality] cap the payload so
/// OCR uploads stay light.
class PluginImagePicker implements ImagePickerService {
  PluginImagePicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pickFromCamera() => _pick(ImageSource.camera);

  @override
  Future<PickedImage?> pickFromGallery() => _pick(ImageSource.gallery);

  Future<PickedImage?> _pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedImage(bytes: bytes, filename: file.name);
  }
}

/// The app-wide [ImagePickerService]. Overridden in tests with a fake.
final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => PluginImagePicker(),
);
