import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'models/models.dart';
import 'models/rent_enums.dart';

/// Network access for the rent-collection queue (EPIC-07 T-003/T-004/T-007
/// endpoints): create a request (from a schedule period or a manual one-off),
/// list/detail the landlord's queue, (re)send the tenant link, and the
/// verify / reject / mark-received lifecycle transitions.
///
/// Rent requests are scoped server-side (`for_user` via lease → landlord), so a
/// foreign/unknown id resolves to **404** (never 403). The landlord is derived
/// server-side and is never sent by the client; the `link_token`, `status` and
/// FK links are read-only. `amount` is sent as a number and comes back as a DRF
/// `DecimalField` string (parsed in [RentRequest]). Errors surface as
/// [ApiException]. `verify` / `mark-received` return the **settled
/// [RentRequest]** (not the Payment) — the receipt lives behind its `receipt_ref`
/// and is fetched separately.
class RentRepository {
  const RentRepository(this._dio);

  final Dio _dio;

  /// `GET /rent-requests` — the caller's request queue (one page). Scoped
  /// server-side via `for_user`, returned in the standard `{results, pagination}`
  /// envelope, so only the `results` array is unwrapped (the queue screen renders
  /// a single page; pagination cursors are ignored for now). An optional
  /// [status] filter maps to `?status=<wire>` so a tab can show only e.g.
  /// proof-submitted requests awaiting verification.
  Future<List<RentRequest>> listQueue({RentRequestStatus? status}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.rentRequests,
        queryParameters: <String, dynamic>{
          if (status != null) 'status': status.wire,
        },
      );
      final data = res.data ?? const <String, dynamic>{};
      final results = data['results'];
      if (results is! List) return const <RentRequest>[];
      return results
          .whereType<Map<String, dynamic>>()
          .map(RentRequest.fromJson)
          .toList(growable: false);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `GET /rent-requests/{id}` — one request the caller owns. Foreign/unknown
  /// ids resolve to **404** (surfaced as an [ApiException]).
  Future<RentRequest> getRequest(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.rentRequest(id),
      );
      return RentRequest.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// `POST /rent-requests` — create a request **from a schedule period** (T-003
  /// §7). Supply only [rentScheduleId]; the lease, amount and period are derived
  /// server-side from the schedule. [sentVia] is sent only when supplied (the
  /// server defaults to WhatsApp). Returns the persisted request with its minted
  /// `link_token`.
  Future<RentRequest> createFromSchedule({
    required String rentScheduleId,
    Channel? sentVia,
  }) {
    return _create(<String, dynamic>{
      'rent_schedule': rentScheduleId,
      if (sentVia != null) 'sent_via': sentVia.wire,
    });
  }

  /// `POST /rent-requests` — create a **manual one-off** request (T-003 §7).
  /// Supply [leaseId] plus [amount] and the `YYYY-MM` [period]; `rent_schedule`
  /// is left null. [sentVia] is sent only when supplied. Returns the persisted
  /// request with its minted `link_token`.
  Future<RentRequest> createManual({
    required String leaseId,
    required double amount,
    required String period,
    Channel? sentVia,
  }) {
    return _create(<String, dynamic>{
      'lease': leaseId,
      'amount': amount,
      'period': period,
      if (sentVia != null) 'sent_via': sentVia.wire,
    });
  }

  /// `POST /rent-requests/{id}/send` — (re)deliver the rent link to the tenant
  /// (T-004 §7). Returns the request with its `sent_at`/`sent_via`/`status`
  /// stamped.
  Future<RentRequest> sendRequest(String id) =>
      _action(ApiEndpoints.rentRequestSend(id));

  /// `POST /rent-requests/{id}/verify` — verify the submitted proof (T-007 §7):
  /// the server creates a Payment + receipt PDF and settles the request/schedule.
  /// Returns the settled [RentRequest] (now `verified`, carrying nothing of the
  /// Payment itself — the receipt is reached via its `receipt_ref`).
  Future<RentRequest> verify(String id) =>
      _action(ApiEndpoints.rentRequestVerify(id));

  /// `POST /rent-requests/{id}/mark-received` — record an off-platform (cash)
  /// payment with no proof and settle (T-007 §7). Returns the settled request.
  Future<RentRequest> markReceived(String id) =>
      _action(ApiEndpoints.rentRequestMarkReceived(id));

  /// `POST /rent-requests/{id}/reject` — reject the request with a required,
  /// non-empty [reason] (T-007 §7). No Payment is created. Returns the rejected
  /// request.
  Future<RentRequest> reject(String id, {required String reason}) =>
      _action(
        ApiEndpoints.rentRequestReject(id),
        body: <String, dynamic>{'reason': reason},
      );

  /// Downloads the verified receipt PDF bytes from a (short-lived) signed [url]
  /// for preview/share (T-013, reusing the EPIC-05 T-008 download seam). The
  /// signed URL is absolute and already authorized, so it is fetched as raw bytes
  /// without the app's auth headers being carried onto a foreign host.
  Future<Uint8List> fetchReceiptBytes(String url) async {
    try {
      final res = await _dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const <int>[]);
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// Shared `POST /rent-requests` create call — both create flows funnel here so
  /// envelope handling and error mapping live in one place.
  Future<RentRequest> _create(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.rentRequests,
        data: body,
      );
      return RentRequest.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  /// Shared POST helper for the `@action` lifecycle transitions, each of which
  /// returns the updated [RentRequest] in the success envelope.
  Future<RentRequest> _action(String path, {Map<String, dynamic>? body}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      return RentRequest.fromJson(res.data ?? const <String, dynamic>{});
    } on DioException catch (e) {
      throw _asApiException(e);
    }
  }

  ApiException _asApiException(DioException e) {
    final err = e.error;
    return err is ApiException ? err : ApiException.fromDio(e);
  }
}
