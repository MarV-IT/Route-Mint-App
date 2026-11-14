import 'package:route_mint_app/core/review/review_service.dart';

class MemoryReviewStore implements ReviewStore {
  String? value;
  bool failRead = false;
  bool failWrite = false;
  Future<void> Function(String)? beforeWrite;
  @override
  Future<String?> read() async {
    if (failRead) throw StateError('read failed');
    return value;
  }

  @override
  Future<void> write(String next) async {
    await beforeWrite?.call(next);
    if (failWrite) throw StateError('write failed');
    value = next;
  }
}

class FakeReviewGateway implements ReviewGateway {
  @override
  bool supported = true;
  bool available = true;
  int availabilityChecks = 0;
  int requests = 0;
  int storeOpens = 0;
  bool failRequest = false;
  bool failStore = false;
  Future<bool> Function()? checkAvailability;
  void Function()? onRequest;
  Future<void> Function()? completeRequest;
  void Function()? onStore;
  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return checkAvailability == null ? available : await checkAvailability!();
  }

  @override
  Future<void> requestReview() async {
    requests++;
    onRequest?.call();
    if (failRequest) throw StateError('native failed');
    await completeRequest?.call();
  }

  @override
  Future<void> openStoreListing() async {
    storeOpens++;
    onStore?.call();
    if (failStore) throw StateError('store failed');
  }
}

class ReviewHarness {
  final store = MemoryReviewStore();
  final gateway = FakeReviewGateway();
  DateTime now = DateTime.utc(2026, 11, 12);
  Duration elapsed = Duration.zero;
  late ReviewService service;

  Future<void> start({bool eligible = false}) async {
    if (eligible) {
      store.value = const ReviewState(
        foregroundMilliseconds: 30 * 60 * 1000,
      ).encode();
    }
    service = ReviewService(
      store: store,
      gateway: gateway,
      now: () => now,
      elapsed: () => elapsed,
    );
    await service.initialize();
  }
}
