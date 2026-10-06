import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Shared chat / inbox visual tokens (Phase 4 Step 5).
abstract final class ChatUiTokens {
  static const double avatarSize = 48;
  static const double sendButtonSize = 42;

  static BorderRadius bubbleRadius({required bool isMine}) {
    return BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );
  }

  static const EdgeInsets bubbleOuterPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 4);

  static const EdgeInsets inputBarPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);
}

class UnreadCountBadge extends StatelessWidget {
  const UnreadCountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Bottom compose row: attach + rounded field + circular send.
///
/// Keeps the text field focused after send so the user can type the next
/// message without tapping the input again.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.hintText,
    required this.sendTooltip,
    this.focusNode,
    this.onAttach,
    this.attachTooltip,
    this.attachIcon = Icons.add_circle_outline,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final String hintText;
  final String sendTooltip;
  final String? attachTooltip;
  final IconData attachIcon;
  final bool enabled;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  FocusNode? _ownedFocus;

  FocusNode get _focus => widget.focusNode ?? _ownedFocus!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocus = FocusNode(debugLabel: 'ChatInputBar');
    }
  }

  @override
  void dispose() {
    _ownedFocus?.dispose();
    super.dispose();
  }

  void _sendAndKeepFocus() {
    widget.onSend();
    // Send button / TextInputAction.send often steals or drops focus; restore
    // it after the frame so the keyboard stays open for the next message.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.enabled) {
        return;
      }
      _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: ChatUiTokens.inputBarPadding,
        child: Row(
          children: [
            if (widget.onAttach != null)
              IconButton(
                tooltip: widget.attachTooltip,
                onPressed: widget.enabled ? widget.onAttach : null,
                icon: Icon(widget.attachIcon),
              ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendAndKeepFocus(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.2,
                    ),
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: ChatUiTokens.sendButtonSize,
              height: ChatUiTokens.sendButtonSize,
              child: IconButton.filled(
                tooltip: widget.sendTooltip,
                onPressed: widget.enabled ? _sendAndKeepFocus : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                ),
                icon: const Icon(Icons.send, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
