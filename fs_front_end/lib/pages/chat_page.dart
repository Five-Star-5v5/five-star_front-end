import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';
import '../providers/auth_provider.dart';
import '../services/messages_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _cpBg = Color(0xFF0A0C10);
const _cpNight = Color(0xFF0B0D11);
const _cpCard = Color(0xFF181A21);
const _cpCard2 = Color(0xFF1E2029);
const _cpBorder2 = Color(0x21FFFFFF);
const _cpAmber = Color(0xFFFF7F2A);
const _cpAmberSoft = Color(0xFFFF9A55);
const _cpAmberD = Color(0xFFD96820);
const _cpWhite = Color(0xFFF0F2F5);
const _cpMuted2 = Color(0x9EF0F2F5);
// ──────────────────────────────────────────────────────────────────────────────

class ChatPage extends StatefulWidget {
  final int friendId;
  final String friendName;
  final String? friendAvatarUrl;

  const ChatPage({
    super.key,
    required this.friendId,
    required this.friendName,
    this.friendAvatarUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Charger la conversation et initialiser WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessagesProvider>();
      provider.initWebSocket();
      provider.startConversation(
        widget.friendId,
        widget.friendName,
        widget.friendAvatarUrl,
      );
    });

    // Écouter le scroll pour charger plus de messages
    _scrollController.addListener(_onScroll);

    // Écouter les changements de texte pour l'indicateur de frappe
    _messageController.addListener(_onTextChanged);
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // En haut de la liste - charger plus de messages
        context.read<MessagesProvider>().loadMoreMessages();
      }
    }
  }

  void _onTextChanged() {
    // Envoyer l'indicateur de frappe (throttled)
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      if (_messageController.text.isNotEmpty) {
        context.read<MessagesProvider>().sendTyping();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    context.read<MessagesProvider>().sendMessage(content);

    // Scroll vers le bas pour voir le nouveau message
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthProvider>().currentUser?.id;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await context.read<MessagesProvider>().closeConversation();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: _cpBg,
        appBar: AppBar(
          backgroundColor: _cpCard,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          flexibleSpace: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.4),
                  radius: 2.4,
                  colors: [Color(0x38FF7F2A), Colors.transparent],
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              // Avatar
              widget.friendAvatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.friendAvatarUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0x1CFF7F2A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.friendName.isNotEmpty
                            ? widget.friendName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.syne(
                          color: _cpAmber,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
              const SizedBox(width: 10),
              Text(
                widget.friendName,
                style: GoogleFonts.syne(
                  color: _cpWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: _cpWhite),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _cpBorder2),
          ),
        ),
        body: Column(
          children: <Widget>[
            // ===== LISTE DES MESSAGES =====
            Expanded(
              child: Consumer<MessagesProvider>(
                builder: (context, provider, _) {
                  if (provider.messagesState == MessagesLoadingState.loading &&
                      provider.activeConversation == null) {
                    return const Center(
                      child: CircularProgressIndicator(color: _cpAmber),
                    );
                  }

                  final messages = provider.activeConversation?.messages ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            size: 80,
                            color: _cpMuted2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun message',
                            style: GoogleFonts.dmSans(
                              fontSize: 18,
                              color: _cpMuted2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Envoyez le premier message !',
                            style: GoogleFonts.dmSans(color: _cpMuted2),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isSender = message.senderId == currentUserId;

                      // Afficher la date si c'est un nouveau jour
                      final showDate =
                          index == 0 ||
                          !_isSameDay(
                            messages[index - 1].createdAt,
                            message.createdAt,
                          );

                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _formatDate(message.createdAt),
                                style: GoogleFonts.dmSans(
                                  color: _cpMuted2,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          _buildMessageBubble(message, isSender),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ===== BARRE DE SAISIE =====
            SafeArea(
              child: Container(
                color: _cpCard,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Consumer<MessagesProvider>(
                  builder: (context, provider, _) {
                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Écrire un message...',
                              hintStyle: GoogleFonts.dmSans(color: _cpMuted2),
                              filled: true,
                              fillColor: _cpCard2,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _cpBorder2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _cpBorder2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: _cpAmber),
                              ),
                            ),
                            style: GoogleFonts.dmSans(color: _cpWhite),
                            onSubmitted: (_) => _sendMessage(),
                            enabled: !provider.isSending,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: provider.isSending ? null : _sendMessage,
                          child: provider.isSending
                              ? Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: _cpCard2,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: _cpNight,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_cpAmberSoft, _cpAmberD],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.send,
                                    color: _cpNight,
                                    size: 18,
                                  ),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isSender) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          gradient: isSender
              ? const LinearGradient(colors: [_cpAmberSoft, _cpAmberD])
              : null,
          color: isSender ? null : _cpCard2,
          border: isSender ? null : Border.all(color: _cpBorder2),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomLeft: isSender
                ? const Radius.circular(20)
                : const Radius.circular(6),
            bottomRight: isSender
                ? const Radius.circular(6)
                : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: GoogleFonts.dmSans(
                color: isSender ? _cpNight : _cpWhite,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: GoogleFonts.dmSans(
                    color: isSender
                        ? _cpNight.withValues(alpha: 0.6)
                        : _cpMuted2,
                    fontSize: 10,
                  ),
                ),
                if (isSender) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? Colors.blue
                        : _cpNight.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return "Aujourd'hui";
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
