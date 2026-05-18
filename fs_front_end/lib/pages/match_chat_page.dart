import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teams_service.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _mcBg = Color(0xFF0A0C10);
const _mcCard = Color(0xFF181A21);
const _mcCard2 = Color(0xFF1E2029);
const _mcBorder2 = Color(0x21FFFFFF);
const _mcAmber = Color(0xFFFF7F2A);
const _mcAmberSoft = Color(0xFFFF9A55);
const _mcAmberD = Color(0xFFD96820);
const _mcAmberDim = Color(0x1CFF7F2A);
const _mcWhite = Color(0xFFF0F2F5);
const _mcMuted2 = Color(0x9EF0F2F5);
const _mcNight = Color(0xFF0B0D11);

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
      backgroundColor: _mcBg,
      appBar: AppBar(
        backgroundColor: _mcCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: _mcCard2,
                shape: BoxShape.circle,
                border: Border.all(color: _mcBorder2),
              ),
              child: const Icon(Icons.arrow_back, color: _mcMuted2, size: 16),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _mcAmberDim,
                borderRadius: BorderRadius.circular(10),
                image: widget.opponentTeamLogoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(widget.opponentTeamLogoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.opponentTeamLogoUrl == null
                  ? const Icon(Icons.groups, color: _mcAmber, size: 20)
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
                      color: _mcWhite,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Chat du match',
                    style: GoogleFonts.dmSans(fontSize: 11, color: _mcMuted2),
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
                    child: CircularProgressIndicator(color: _mcAmber),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.forum_outlined,
                          size: 80,
                          color: _mcMuted2,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun message',
                          style: GoogleFonts.dmSans(
                            fontSize: 18,
                            color: _mcMuted2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Commencez à discuter avec votre adversaire !',
                          style: GoogleFonts.dmSans(
                            color: _mcMuted2,
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
                                  color: _mcMuted2,
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
                color: _mcCard,
                border: Border(top: BorderSide(color: _mcBorder2)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: GoogleFonts.dmSans(color: _mcMuted2),
                        filled: true,
                        fillColor: _mcCard2,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _mcBorder2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _mcBorder2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _mcAmber),
                        ),
                      ),
                      style: GoogleFonts.dmSans(color: _mcWhite),
                      cursorColor: _mcAmber,
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
                        color: _isSending ? _mcCard2 : null,
                        gradient: _isSending
                            ? null
                            : const LinearGradient(
                                colors: [_mcAmberSoft, _mcAmberD],
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
                                  color: _mcAmber,
                                ),
                              ),
                            )
                          : const Icon(Icons.send, color: _mcNight, size: 18),
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
                  color: _mcMuted2,
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
                            color: _mcNight,
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
                  color: isMyTeam ? null : _mcCard2,
                  gradient: isMyTeam
                      ? const LinearGradient(
                          colors: [_mcAmberSoft, _mcAmberD],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: isMyTeam ? null : Border.all(color: _mcBorder2),
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
                            color: _mcAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Contenu du message
                    Text(
                      message.content,
                      style: GoogleFonts.dmSans(
                        color: isMyTeam ? _mcNight : _mcWhite,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Heure
                    Text(
                      _formatTime(message.createdAt),
                      style: GoogleFonts.dmSans(color: _mcMuted2, fontSize: 10),
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
