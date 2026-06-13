import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'chat_repository.dart';
import 'models/chat_message.dart';

/// The shared [ChatRepository], backed by the app-wide Dio client.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(dioClientProvider)),
);

// ── Conversation state ────────────────────────────────────────────────────---

/// State snapshot for the active chat session.
class ChatState {
  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  /// Ordered message list, oldest first (for display).
  final List<ChatMessage> messages;

  /// True while the initial history fetch is in flight.
  final bool isLoading;

  /// True while a send request is in flight (input should be disabled).
  final bool isSending;

  /// Non-null when the last operation failed.
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isSending: isSending ?? this.isSending,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Drives the in-app chatbot: loads history on first build and exposes
/// [send] for new user turns.
///
/// Own-data safety: the repository has no user-id parameter — the backend
/// resolves everything from `request.user`, so a caller structurally cannot
/// request another user's messages.
class ChatController extends AutoDisposeNotifier<ChatState> {
  @override
  ChatState build() {
    // Kick off history fetch immediately.
    _loadHistory();
    return const ChatState(isLoading: true);
  }

  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  Future<void> _loadHistory() async {
    try {
      final msgs = await _repo.history();
      // History endpoint returns newest-first; reverse for chronological display.
      state = state.copyWith(
        messages: msgs.reversed.toList(),
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Appends [text] to the conversation and awaits the assistant reply.
  ///
  /// A local optimistic user message is inserted immediately; an optimistic
  /// assistant placeholder (with [ChatMessage.isStreaming] = `true`) is added
  /// while the round-trip is in flight. Both are replaced/finalised when the
  /// server reply arrives.
  Future<void> send(String text) async {
    if (text.trim().isEmpty || state.isSending) return;

    final optimistic = ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.user,
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    // Streaming placeholder shown while the round-trip is in flight.
    final streamingPlaceholder = ChatMessage(
      id: 'streaming-${DateTime.now().millisecondsSinceEpoch}',
      role: ChatRole.assistant,
      content: '',
      createdAt: DateTime.now(),
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, optimistic, streamingPlaceholder],
      isSending: true,
      clearError: true,
    );

    try {
      final reply = await _repo.send(text.trim());
      // Remove the streaming placeholder and append the confirmed reply.
      state = state.copyWith(
        messages: [
          ...state.messages
              .where((m) => m.id != streamingPlaceholder.id)
              .toList(),
          reply,
        ],
        isSending: false,
      );
    } catch (e) {
      // Remove both the optimistic user message and the streaming placeholder
      // on failure, then surface the error.
      state = state.copyWith(
        messages: state.messages
            .where(
              (m) => m.id != optimistic.id && m.id != streamingPlaceholder.id,
            )
            .toList(),
        isSending: false,
        error: e.toString(),
      );
    }
  }

  /// Re-fetches conversation history (pull-to-refresh or retry after error).
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _loadHistory();
  }
}

/// Exposes the active chat session's [ChatState].
///
/// Auto-disposed so history is re-fetched each time the sheet opens (keeping
/// the conversation fresh without a manual refresh).
final chatProvider =
    NotifierProvider.autoDispose<ChatController, ChatState>(
  ChatController.new,
);

/// Alias for [chatProvider] used as the `chatControllerProvider` in tests and
/// call sites that prefer the controller-centric naming from T-007.
final chatControllerProvider = chatProvider;

/// Convenience provider that exposes only the ordered message list from the
/// active session. Useful for widgets that only need to display history and
/// don't need the full [ChatState].
final chatHistoryProvider = Provider.autoDispose<List<ChatMessage>>((ref) {
  return ref.watch(chatProvider).messages;
});
