import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/flags_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/chat_providers.dart';
import '../../data/models/chat_message.dart';

// ── Guardrail keywords ───────────────────────────────────────────────────────

/// Keywords that trigger the extended guardrail disclaimer overlay when they
/// appear in an assistant response. Matches the backend T-004 list for parity.
const _guardrailKeywords = [
  'legal advice',
  'financial advice',
  'আইনি পরামর্শ',
  'আর্থিক পরামর্শ',
  'consult a lawyer',
  'consult a financial',
  'আইনজীবী',
  'ট্যাক্স পরামর্শ',
  'tax advice',
  'investment advice',
  'বিনিয়োগ পরামর্শ',
];

/// Returns `true` when [content] contains one of the [_guardrailKeywords].
bool _containsGuardrailKeyword(String content) {
  final lower = content.toLowerCase();
  return _guardrailKeywords.any((kw) => lower.contains(kw.toLowerCase()));
}

// ── Public API ───────────────────────────────────────────────────────────────

/// Opens the [ChatSheet] as a modal bottom-sheet from any screen.
///
/// Usage:
/// ```dart
/// showChatSheet(context);
/// ```
///
/// The sheet auto-disposes its chat state on close so fresh history is loaded
/// each time it opens (per T-007 `chatProvider` auto-dispose behaviour).
Future<void> showChatSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: KhatirColors.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(KhatirRadius.xl),
      ),
    ),
    builder: (_) => const ChatSheet(),
  );
}

/// Reusable chat bottom-sheet widget (EPIC-23 T-006).
///
/// Features:
/// - Message list: user messages right-aligned with sage background; assistant
///   messages left-aligned with card background.
/// - Typing/streaming indicator (three animated dots) while isSending = true.
/// - Bilingual disclaimer banner (EN + BN).
/// - Guardrail overlay when the assistant response contains legal/financial
///   advice keywords.
/// - Feature-flag gate: when `chatbot_enabled` is off, shows a disabled state
///   and the send button is disabled.
///
/// All colours and spacing come from [KhatirColors] / [KhatirSpacing] /
/// [KhatirRadius] — no inline hex/px.
class ChatSheet extends HookConsumerWidget {
  const ChatSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final flags = ref.watch(flagsProvider);
    final chatbotEnabled = flags.isEnabled('chatbot_enabled');

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────────────
            const _DragHandle(),
            // ── Header ───────────────────────────────────────────────────────
            _Header(title: l10n.chat_title),
            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: chatbotEnabled
                  ? _ChatBody(scrollController: scrollController)
                  : _DisabledBody(l10n: l10n),
            ),
            // ── Disclaimer ───────────────────────────────────────────────────
            _DisclaimerBanner(text: l10n.chat_disclaimer),
            // ── Input ────────────────────────────────────────────────────────
            _InputBar(enabled: chatbotEnabled),
          ],
        );
      },
    );
  }
}

// ── Internal widgets ─────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s3),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: KhatirColors.line,
          borderRadius: BorderRadius.circular(KhatirRadius.pill),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        0,
        KhatirSpacing.s5,
        KhatirSpacing.s3,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: KhatirColors.sageBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🤖', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: KhatirColors.muted),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}

/// The main scrollable message list, shown when `chatbot_enabled` is on.
class _ChatBody extends ConsumerWidget {
  const _ChatBody({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chatState = ref.watch(chatProvider);

    if (chatState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: KhatirColors.sage),
      );
    }

    if (chatState.error != null && chatState.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KhatirSpacing.s6),
          child: Text(
            l10n.chat_loading_error,
            style: AppTextStyles.bodyMedium
                .copyWith(color: KhatirColors.mutedDk),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (chatState.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(KhatirSpacing.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💬', style: TextStyle(fontSize: 40)),
              const SizedBox(height: KhatirSpacing.s3),
              Text(
                l10n.chat_empty,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: KhatirColors.mutedDk),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s2,
      ),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final msg = chatState.messages[index];
        return _MessageBubble(
          key: ValueKey(msg.id),
          message: msg,
        );
      },
    );
  }
}

/// A single chat message bubble.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isUser = message.role == ChatRole.user;

    // Guardrail overlay for assistant messages containing advice keywords.
    final showGuardrail =
        !isUser && _containsGuardrailKeyword(message.content);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s1),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // Assistant avatar.
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(
                right: KhatirSpacing.s2,
                top: KhatirSpacing.s1,
              ),
              decoration: const BoxDecoration(
                color: KhatirColors.sageBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🤖', style: TextStyle(fontSize: 13)),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s4,
                    vertical: KhatirSpacing.s3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isUser ? KhatirColors.sageBg : KhatirColors.card,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                          isUser ? KhatirRadius.md : KhatirRadius.xs),
                      topRight: Radius.circular(
                          isUser ? KhatirRadius.xs : KhatirRadius.md),
                      bottomLeft:
                          const Radius.circular(KhatirRadius.md),
                      bottomRight:
                          const Radius.circular(KhatirRadius.md),
                    ),
                    border: isUser
                        ? null
                        : Border.all(color: KhatirColors.line),
                  ),
                  child: message.isStreaming
                      ? const _TypingDots()
                      : Text(
                          message.content,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isUser
                                ? KhatirColors.ink
                                : KhatirColors.ink2,
                          ),
                        ),
                ),
                // Guardrail disclaimer below the assistant bubble.
                if (showGuardrail) ...[
                  const SizedBox(height: KhatirSpacing.s1),
                  Container(
                    padding: const EdgeInsets.all(KhatirSpacing.s2),
                    decoration: BoxDecoration(
                      color: KhatirColors.butterBg,
                      borderRadius:
                          BorderRadius.circular(KhatirRadius.sm),
                      border: Border.all(color: KhatirColors.butter),
                    ),
                    child: Text(
                      l10n.chat_guardrail_disclaimer,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: KhatirColors.ink2,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three animated dots shown as the streaming/typing indicator.
class _TypingDots extends HookWidget {
  const _TypingDots();

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 900),
    )..repeat();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            // Stagger each dot by 0.33 of the animation period.
            final offset = i * 0.33;
            final t = ((controller.value + offset) % 1.0);
            final opacity = t < 0.5 ? (t * 2) : (1.0 - (t - 0.5) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s1),
              child: Opacity(
                opacity: opacity.clamp(0.2, 1.0),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: KhatirColors.sage,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

/// The disabled-state body shown when `chatbot_enabled` flag is off.
class _DisabledBody extends StatelessWidget {
  const _DisabledBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: KhatirColors.line,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 30,
                color: KhatirColors.muted,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.chat_disabled_title,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              l10n.chat_disabled_body,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// The bilingual disclaimer banner pinned above the input bar.
class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s2,
      ),
      decoration: const BoxDecoration(
        color: KhatirColors.butterBg,
        border: Border(top: BorderSide(color: KhatirColors.butter)),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.ink2,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// The message input bar with text field and send button.
class _InputBar extends HookConsumerWidget {
  const _InputBar({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = useTextEditingController();
    final focusNode = useFocusNode();
    final chatState = ref.watch(chatProvider);
    final isBusy = chatState.isSending;

    Future<void> send() async {
      final text = controller.text.trim();
      if (text.isEmpty || isBusy || !enabled) return;
      controller.clear();
      final messenger = ScaffoldMessenger.maybeOf(context);
      try {
        await ref.read(chatProvider.notifier).send(text);
      } catch (_) {
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.chat_send_error)),
        );
      }
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          KhatirSpacing.s4,
          KhatirSpacing.s3,
          KhatirSpacing.s4,
          KhatirSpacing.s4 +
              MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled && !isBusy,
                onSubmitted: (_) => send(),
                textInputAction: TextInputAction.send,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: l10n.chat_input_hint,
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: KhatirColors.muted),
                  filled: true,
                  fillColor: KhatirColors.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s4,
                    vertical: KhatirSpacing.s3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(KhatirRadius.pill),
                    borderSide:
                        const BorderSide(color: KhatirColors.line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(KhatirRadius.pill),
                    borderSide:
                        const BorderSide(color: KhatirColors.line),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(KhatirRadius.pill),
                    borderSide: const BorderSide(
                        color: KhatirColors.sage, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(KhatirRadius.pill),
                    borderSide:
                        const BorderSide(color: KhatirColors.line),
                  ),
                ),
              ),
            ),
            const SizedBox(width: KhatirSpacing.s2),
            // Send button — disabled when flag is off or a send is in flight.
            _SendButton(
              enabled: enabled && !isBusy,
              onPressed: send,
              isBusy: isBusy,
              tooltip: l10n.chat_send,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.enabled,
    required this.onPressed,
    required this.isBusy,
    required this.tooltip,
  });

  final bool enabled;
  final VoidCallback onPressed;
  final bool isBusy;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? KhatirColors.sage : KhatirColors.line,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s3),
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: KhatirColors.cream,
                    ),
                  )
                : Icon(
                    Icons.send_rounded,
                    color:
                        enabled ? KhatirColors.cream : KhatirColors.muted,
                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }
}
