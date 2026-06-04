import 'dart:io';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../../core/network/dio_client.dart';
import 'models/family_member.dart';
import 'models/tenant.dart';
import 'models/tenant_create_result.dart';
import 'tenant_repository.dart';

/// The shared [TenantRepository], backed by the app-wide dio client.
final tenantRepositoryProvider = Provider<TenantRepository>(
  (ref) => TenantRepository(ref.watch(dioClientProvider)),
);

// ── Tenants of a unit ────────────────────────────────────────────────────--

/// Loads and mutates the tenants holding a lease on one unit, exposing
/// [AsyncValue]. Keyed by unit id via [family] — shared by the add-tenant flows
/// (manual/OCR/voice) so creating a tenant refreshes the unit's list in place.
///
/// [build] fetches `GET /units/{id}/tenants`. [create] POSTs the reviewed
/// fields then re-fetches so the list stays consistent with the server (the
/// source of truth); it returns the new (masked) tenant for callers that route
/// on it.
class UnitTenantsController extends FamilyAsyncNotifier<List<Tenant>, String> {
  @override
  Future<List<Tenant>> build(String unitId) => _repo.listUnitTenants(unitId);

  TenantRepository get _repo => ref.read(tenantRepositoryProvider);

  /// Re-fetches this unit's tenants into [state].
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.listUnitTenants(arg));
  }

  /// Creates a tenant (from reviewed fields), then refreshes this unit's list.
  /// [nidNumber] is the plaintext NID the server encrypts; it is never echoed
  /// back. Returns the persisted, masked tenant.
  Future<Tenant> create({
    required String name,
    String? nidNumber,
    DateTime? dob,
    String? address,
    String? photoRef,
    List<FamilyMember>? familyMembers,
  }) async {
    final result = await createDetailed(
      name: name,
      nidNumber: nidNumber,
      dob: dob,
      address: address,
      photoRef: photoRef,
      familyMembers: familyMembers,
    );
    return result.tenant;
  }

  /// Like [create], but returns the full [TenantCreateResult] (masked tenant +
  /// optional free-tier usage) so the convergent save action (T-016) can route
  /// on the tenant *and* surface the "1/2 free" toast. Refreshes this unit's
  /// list after the create so it stays consistent with the server.
  Future<TenantCreateResult> createDetailed({
    required String name,
    String? nidNumber,
    DateTime? dob,
    String? address,
    String? photoRef,
    List<FamilyMember>? familyMembers,
  }) async {
    final result = await _repo.createTenantDetailed(
      name: name,
      nidNumber: nidNumber,
      dob: dob,
      address: address,
      photoRef: photoRef,
      familyMembers: familyMembers,
    );
    await refresh();
    return result;
  }
}

/// Tenants of a unit, keyed by unit id.
final unitTenantsProvider = AsyncNotifierProvider.family<UnitTenantsController,
    List<Tenant>, String>(
  UnitTenantsController.new,
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

/// The bytes + filename of a recorded audio clip, decoupled from the recorder
/// plugin so the voice screen and its tests do not depend on the plugin types.
class RecordedAudio {
  const RecordedAudio({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Records a short Bangla voice clip for the voice tenant-entry flow (T-012).
/// An interface (not a concrete plugin call) so widget tests inject a fake
/// without the platform-channel `record` plugin or a live microphone.
///
/// The recorder owns the mic permission prompt: [start] requests permission and
/// returns `false` if it is denied (the caller surfaces the permission state).
abstract class AudioRecorderService {
  /// Requests mic permission (if needed) and begins recording. Returns `true`
  /// when recording started, `false` when permission was denied/unavailable.
  Future<bool> start();

  /// Stops recording and returns the captured clip, or `null` if nothing was
  /// recorded. The bytes are uploaded then discarded — never persisted.
  Future<RecordedAudio?> stop();

  /// Aborts an in-flight recording without producing a clip (e.g. on dispose).
  Future<void> cancel();

  /// Releases native resources held by the recorder.
  Future<void> dispose();
}

/// Default [AudioRecorderService] backed by the `record` plugin.
///
/// Records to a temporary file, reads it into memory for the upload, then
/// deletes the temp file so the clip never lingers on the device beyond the
/// upload (privacy, T-012 §14). [AudioEncoder.aacLc] / `.m4a` keeps the payload
/// light for the ASR upload.
class PluginAudioRecorder implements AudioRecorderService {
  PluginAudioRecorder([AudioRecorder? recorder])
      : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _path;

  @override
  Future<bool> start() async {
    if (!await _recorder.hasPermission()) return false;
    final dir = Directory.systemTemp.createTempSync('khatir_voice');
    final path = '${dir.path}/voice.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    _path = path;
    return true;
  }

  @override
  Future<RecordedAudio?> stop() async {
    final path = await _recorder.stop();
    _path = null;
    if (path == null) return null;
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    // Discard the local clip immediately after reading it for the upload.
    try {
      await file.delete();
    } catch (_) {
      // Best-effort cleanup; the temp dir is reclaimed by the OS regardless.
    }
    return RecordedAudio(bytes: bytes, filename: 'voice.m4a');
  }

  @override
  Future<void> cancel() async {
    await _recorder.cancel();
    final path = _path;
    _path = null;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        // Ignore — nothing to clean up if the file is already gone.
      }
    }
  }

  @override
  Future<void> dispose() => _recorder.dispose();
}

/// The app-wide [AudioRecorderService]. Overridden in tests with a fake.
final audioRecorderServiceProvider = Provider<AudioRecorderService>(
  (ref) => PluginAudioRecorder(),
);
