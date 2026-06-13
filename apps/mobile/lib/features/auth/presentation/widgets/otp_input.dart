import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';

/// N-box OTP input mirroring the `otp` prototype: a centred row of rounded
/// boxes, each holding one digit, with auto-advance and auto-submit. Filled /
/// active boxes get a sage border; errored boxes a danger border. All visual
/// values come from [KhatirColors] / [KhatirSpacing] / [KhatirRadius].
class OtpInput extends StatefulWidget {
  const OtpInput({
    super.key,
    this.length = 6,
    required this.onChanged,
    required this.onCompleted,
    this.hasError = false,
    this.enabled = true,
    this.autofocus = true,
  });

  /// Number of digits / boxes.
  final int length;

  /// Called whenever the assembled code changes.
  final ValueChanged<String> onChanged;

  /// Called once all [length] boxes are filled (auto-submit trigger).
  final ValueChanged<String> onCompleted;

  /// Renders the boxes in the error state (danger border).
  final bool hasError;

  /// Whether the boxes accept input (disabled while verifying).
  final bool enabled;

  /// Whether to focus the first box on mount.
  final bool autofocus;

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers =
        List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  /// Clears all boxes and refocuses the first one (used on an error to let the
  /// user retype).
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    if (widget.length > 0) _focusNodes.first.requestFocus();
    widget.onChanged('');
  }

  void _onChanged(int index, String value) {
    // Handle paste / multi-char: distribute across boxes from this index.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final lastFilled =
          (digits.length).clamp(0, widget.length) - 1;
      if (lastFilled >= 0 && lastFilled < widget.length - 1) {
        _focusNodes[lastFilled + 1].requestFocus();
      } else {
        _focusNodes.last.unfocus();
      }
      _emit();
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _emit();
  }

  void _emit() {
    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length &&
        code.split('').every((c) => c.isNotEmpty)) {
      widget.onCompleted(code);
    }
  }

  KeyEventResult _handleKey(int index, FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      _emit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < widget.length; i++) ...[
          if (i > 0) const SizedBox(width: KhatirSpacing.s3),
          _OtpBox(
            key: Key('otp_box_$i'),
            controller: _controllers[i],
            focusNode: _focusNodes[i],
            enabled: widget.enabled,
            autofocus: widget.autofocus && i == 0,
            hasError: widget.hasError,
            onChanged: (v) => _onChanged(i, v),
            onKey: (node, event) => _handleKey(i, node, event),
          ),
        ],
      ],
    );
  }
}

/// A single OTP digit box.
class _OtpBox extends StatelessWidget {
  const _OtpBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.autofocus,
    required this.hasError,
    required this.onChanged,
    required this.onKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool autofocus;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final KeyEventResult Function(FocusNode, KeyEvent) onKey;

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.isNotEmpty;
    final borderColor = hasError
        ? KhatirColors.danger
        : (filled || focusNode.hasFocus ? KhatirColors.sage : KhatirColors.line);

    return SizedBox(
      width: 52,
      height: 64,
      child: Focus(
        onKeyEvent: onKey,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autofocus: autofocus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          // Allow paste of the full code (handled by the parent).
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTextStyles.headlineMedium.copyWith(fontSize: 26),
          cursorColor: KhatirColors.sageDk,
          onChanged: onChanged,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: KhatirColors.card,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.md),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.md),
              borderSide: BorderSide(
                color: hasError ? KhatirColors.danger : KhatirColors.sage,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.md),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
