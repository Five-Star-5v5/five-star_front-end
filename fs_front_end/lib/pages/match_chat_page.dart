import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teams_service.dart';

import '../theme/app_colors.dart';

/// Page de chat entre deux équipes pour un match confirmé
class MatchChatPage extends StatefulWidget {
  final int challengeId;
  final String myTeamName;
  final String opponentTeamName;
  final String? opponentTeamLogoUrl;
  final int myTeamId;

  const MatchChatPage({
    super.key,
    required this.challengeId,
    required this.myTeamName,
    required this.opponentTeamName,
    this.opponentTeamLogoUrl,
    required this.myTeamId,
  });

  @override
  State<MatchChatPage> createState() => _MatchChatPageState();
}

class _MatchChatPageState extends State<MatchChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TeamsService _teamsService = TeamsService.instance;

  List<MatchChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupWebSocket();
  }

  Future<void> _loadData() async {
    // Charger les messages
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    final messages = await _teamsService.getMatchMessages(widget.challengeId);

    setState(() {
      _messages = messages;
      _isLoading = false;
    });

    // Marquer comme lus
    await _teamsService.markMatchMessagesAsRead(widget.challengeId);

    // Scroll vers le bas
    _scrollToBottom();
  }

  void _setupWebSocket() {
    // Configurer le callback pour les nouveaux messages
    _teamsService.onNewMatchMessage = (message) {
      if (message.challengeId == widget.challengeId) {
        setState(() {
          // Éviter les doublons
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
          }
        });
        _scrollToBottom();
        // Marquer comme lu
        _teamsService.markMatchMessagesAsRead(widget.challengeId);
      }
    };

    _teamsService.onMatchChatConnected = () {
    };

    _teamsService.onMatchChatDisconnected = () {
    };

    // Se connecter au WebSocket
    _teamsService.connectToMatchChat(widget.challengeId);
  }

  @override
  void dispose() {
    _teamsService.onNewMatchMessage = null;
    _teamsService.onMatchChatConnected = null;
    _teamsService.onMatchChatDisconnected = null;
    _teamsService.disconnectFromMatchChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    setState(() => _isSending = true);

    // Utiliser WebSocket si connecté
    if (_teamsService.isMatchChatConnected) {
      _teamsService.sendMatchMessageWs(content);
      setState(() => _isSending = false);
    } else {
      // Fallback sur REST
      final message = await _teamsService.sendMatchMessage(
        widget.challengeId,
        content,
      );
      if (message != null) {
        setState(() {
          if (!_messages.any((m) => m.id == message.id)) {
            _messages.add(message);
          }
        });
        _scrollToBottom();
      }
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border2),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.muted2, size: 16),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(10),
                image: widget.opponentTeamLogoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.opponentTeamLogoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.opponentTeamLogoUrl == null
                  ? const Icon(Icons.groups, color: AppColors.amber, size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.opponentTeamName,
                    style: GoogleFonts.syne(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Chat du match',
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted2),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      ),
      body: Column(
        children: <Widget>[
          // ===== LISTE DES MESSAGES =====
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.forum_outlined,
                          size: 80,
                          color: AppColors.muted2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            color: AppColors.muted2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez à discuter avec votre adversaire !',
                          style: GoogleFonts.dmSans(
                            color: AppColors.muted2,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMyTeam = message.senderTeamId == widget.myTeamId;

                      // Afficher la date si c'est un nouveau jour
                      final showDate =
                          index == 0 ||
                          !_isSameDay(
                            _messages[index - 1].createdAt,
                            message.createdAt,
                          );

                      // Afficher le nom de l'expéditeur si ce n'est pas mon équipe
                      // et si le message précédent n'est pas du même utilisateur
                      final showSenderName =
                          !isMyTeam &&
                          (index == 0 ||
                              _messages[index - 1].senderUserId !=
                                  message.senderUserId);

                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                _formatDate(message.createdAt),
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.muted2,
                                ),
                              ),
                            ),
                          _buildMessageBubble(
                            message,
                            isMyTeam,
                            showSenderName,
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // ===== BARRE DE SAISIE =====
          SafeArea(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(top: BorderSide(color: AppColors.border2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: GoogleFonts.dmSans(color: AppColors.muted2),
                        filled: true,
                        fillColor: AppColors.card2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.border2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.amber),
                        ),
                      ),
                      style: GoogleFonts.dmSans(color: AppColors.white),
                      cursorColor: AppColors.amber,
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isSending,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isSending ? AppColors.card2 : null,
                        gradient: _isSending
                            ? null
                            : const LinearGradient(
                                colors: [AppColors.amberSoft, AppColors.amberD],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      ),
                      child: _isSending
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.amber,
                                ),
                              ),
                            )
                          : const Icon(Icons.send, color: AppColors.night, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    MatchChatMessage message,
    bool isMyTeam,
    bool showSenderName,
  ) {
    return Align(
      alignment: isMyTeam ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar pour l'adversaire
            if (!isMyTeam) ...[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.muted2,
                  shape: BoxShape.circle,
                  image: message.senderAvatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(message.senderAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: message.senderAvatarUrl == null
                    ? Center(
                        child: Text(
                          message.senderUsername.isNotEmpty
                              ? message.senderUsername[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.syne(
                            color: AppColors.night,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            // Bulle de message
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: isMyTeam ? null : AppColors.card2,
                  gradient: isMyTeam
                      ? const LinearGradient(
                          colors: [AppColors.amberSoft, AppColors.amberD],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: isMyTeam ? null : Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.circular(20).copyWith(
                    bottomRight: isMyTeam
                        ? const Radius.circular(6)
                        : const Radius.circular(20),
                    bottomLeft: isMyTeam
                        ? const Radius.circular(20)
                        : const Radius.circular(6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMyTeam
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Nom de l'expéditeur + nom d'équipe
                    if (showSenderName)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${message.senderUsername} (${message.senderTeamName})',
                          style: GoogleFonts.syne(
                            color: AppColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Contenu du message
                    Text(
                      message.content,
                      style: GoogleFonts.dmSans(
                        color: isMyTeam ? AppColors.night : AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Heure
                    Text(
                      _formatTime(message.createdAt),
                      style: GoogleFonts.dmSans(color: AppColors.muted2, fontSize: 10),
                    ),
                  ],
                ),
              ),
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
