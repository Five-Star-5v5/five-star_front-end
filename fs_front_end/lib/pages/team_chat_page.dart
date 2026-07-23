import 'package:flutter/material.dart';
import 'package:five_star_5v5/theme/app_typography.dart';
import 'package:provider/provider.dart';
import '../providers/teams_provider.dart';
import '../providers/auth_provider.dart';
import '../services/teams_service.dart';

import '../theme/app_colors.dart';

class TeamChatPage extends StatefulWidget {
  final int teamId;
  final String teamName;
  final String? teamLogoUrl;
  final int? ownerId; // ID du propriétaire de l'équipe

  const TeamChatPage({
    super.key,
    required this.teamId,
    required this.teamName,
    this.teamLogoUrl,
    this.ownerId,
  });

  @override
  State<TeamChatPage> createState() => _TeamChatPageState();
}

class _TeamChatPageState extends State<TeamChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Charger les messages et se connecter au WebSocket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<TeamsProvider>();
      provider.loadTeamMessages(widget.teamId);
      // Se connecter au WebSocket pour le temps réel
      provider.connectToTeamChat(widget.teamId);
      // Marquer les messages comme lus à l'ouverture
      provider.markMessagesAsRead(widget.teamId);
    });

    // Écouter le scroll pour charger plus de messages
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels == 0) {
        // En haut de la liste - charger les messages plus anciens
        final provider = context.read<TeamsProvider>();
        final messages = provider.getMessagesForTeam(widget.teamId);
        if (messages.isNotEmpty) {
          // Le premier message est le plus ancien (ordre chronologique)
          provider.loadTeamMessages(widget.teamId, beforeId: messages.first.id);
        }
      }
    }
  }

  @override
  void dispose() {
    // Déconnecter du WebSocket quand on quitte la page
    context.read<TeamsProvider>().disconnectFromTeamChat();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    // Utiliser WebSocket si connecté, sinon HTTP
    final provider = context.read<TeamsProvider>();
    if (provider.isTeamChatConnected) {
      provider.sendMessageRealtime(content);
    } else {
      provider.sendMessage(widget.teamId, content);
    }

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
    final isOwner = widget.ownerId != null && currentUserId == widget.ownerId;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border2),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: AppColors.muted2,
                size: 16,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            // Logo de l'équipe
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.amberDim,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.teamLogoUrl != null
                  ? Image.network(
                      widget.teamLogoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.groups,
                        color: AppColors.amber,
                        size: 20,
                      ),
                    )
                  : const Icon(Icons.groups, color: AppColors.amber, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teamName,
                    style: AppTypography.display(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Chat d'équipe",
                    style: AppTypography.body(
                      fontSize: 11,
                      color: AppColors.muted2,
                    ),
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
          // ===== EN-TÊTE AVEC BADGE MEMBRE ET BOUTON QUITTER =====
          if (!isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                  bottom: BorderSide(color: AppColors.border2, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Badge "MEMBRE"
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amberDim,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'MEMBRE',
                      style: AppTypography.display(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Bouton "Quitter l'équipe"
                  GestureDetector(
                    onTap: () => _showLeaveTeamDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.roseDim,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.rose),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.exit_to_app,
                            size: 16,
                            color: AppColors.rose,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Quitter l'équipe",
                            style: AppTypography.display(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ===== LISTE DES MESSAGES =====
          Expanded(
            child: Consumer<TeamsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoadingMessages &&
                    provider.getMessagesForTeam(widget.teamId).isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.amber),
                  );
                }

                final messages = provider.getMessagesForTeam(widget.teamId);

                if (messages.isEmpty) {
                  return Center(
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
                          style: AppTypography.body(
                            fontSize: 18,
                            color: AppColors.muted2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Démarrez la conversation avec votre équipe !',
                          style: AppTypography.body(color: AppColors.muted2),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Les messages sont en ordre chronologique (plus ancien -> plus récent)
                // Pas besoin d'inverser
                final displayMessages = messages;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    final message = displayMessages[index];
                    final isSender = message.sender.id == currentUserId;

                    // Afficher la date si c'est un nouveau jour
                    final showDate =
                        index == 0 ||
                        !_isSameDay(
                          displayMessages[index - 1].createdAt,
                          message.createdAt,
                        );

                    // Afficher le nom de l'expéditeur si ce n'est pas nous
                    // et si le message précédent n'est pas du même expéditeur
                    final showSenderName =
                        !isSender &&
                        (index == 0 ||
                            displayMessages[index - 1].sender.id !=
                                message.sender.id);

                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _formatDate(message.createdAt),
                              style: AppTypography.body(
                                fontSize: 11,
                                color: AppColors.muted2,
                              ),
                            ),
                          ),
                        // Message système (ex: "X a quitté l'équipe")
                        if (message.isSystemMessage)
                          _buildSystemMessage(message)
                        else
                          _buildMessageBubble(
                            message,
                            isSender,
                            showSenderName,
                          ),
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
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top: BorderSide(color: AppColors.border2, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Consumer<TeamsProvider>(
                builder: (context, provider, _) {
                  return Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Écrire un message...',
                            hintStyle: AppTypography.body(
                              color: AppColors.muted2,
                            ),
                            filled: true,
                            fillColor: AppColors.card2,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                          style: AppTypography.body(color: AppColors.white),
                          cursorColor: AppColors.amber,
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !provider.isSendingMessage,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: provider.isSendingMessage ? null : _sendMessage,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: provider.isSendingMessage
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      AppColors.amberSoft,
                                      AppColors.amberD,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            color: provider.isSendingMessage
                                ? AppColors.card2
                                : null,
                          ),
                          child: Center(
                            child: provider.isSendingMessage
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.muted2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: AppColors.night,
                                    size: 18,
                                  ),
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
    );
  }

  /// Widget pour afficher un message système
  Widget _buildSystemMessage(TeamChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.muted2),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content,
              style: AppTypography.body(
                color: AppColors.muted2,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    TeamChatMessage message,
    bool isSender,
    bool showSenderName,
  ) {
    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar pour les autres
            if (!isSender) ...[
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.amberDim,
                ),
                clipBehavior: Clip.antiAlias,
                child: message.sender.avatarUrl != null
                    ? Image.network(
                        message.sender.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            message.sender.username.isNotEmpty
                                ? message.sender.username[0].toUpperCase()
                                : '?',
                            style: AppTypography.display(
                              color: AppColors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          message.sender.username.isNotEmpty
                              ? message.sender.username[0].toUpperCase()
                              : '?',
                          style: AppTypography.display(
                            color: AppColors.amber,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
            ],
            // Bulle de message
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  gradient: isSender
                      ? const LinearGradient(
                          colors: [AppColors.amberSoft, AppColors.amberD],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSender ? null : AppColors.card2,
                  border: isSender
                      ? null
                      : Border.all(color: AppColors.border2),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: isSender
                        ? const Radius.circular(20)
                        : const Radius.circular(6),
                    bottomRight: isSender
                        ? const Radius.circular(6)
                        : const Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isSender
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Nom de l'expéditeur
                    if (showSenderName)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message.sender.username,
                          style: AppTypography.display(
                            color: AppColors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Contenu du message
                    Text(
                      message.content,
                      style: AppTypography.body(
                        color: isSender ? AppColors.night : AppColors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Heure
                    Text(
                      _formatTime(message.createdAt),
                      style: AppTypography.body(
                        color: AppColors.muted2,
                        fontSize: 10,
                      ),
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

  /// Affiche une boîte de dialogue pour confirmer la sortie de l'équipe
  void _showLeaveTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.roseDim,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.warning_rounded,
                        color: AppColors.rose,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Quitter l'équipe",
                      style: AppTypography.display(
                        color: AppColors.rose,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Corps
                Text(
                  'Êtes-vous sûr de vouloir quitter "${widget.teamName}" ?\n\n'
                  'Vous ne recevrez plus les messages de cette équipe.',
                  style: AppTypography.body(color: AppColors.muted2),
                ),
                const SizedBox(height: 24),
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Annuler',
                              style: AppTypography.display(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(dialogContext).pop();

                          // Afficher un indicateur de chargement
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext loadingContext) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.rose,
                                ),
                              );
                            },
                          );

                          // Quitter l'équipe
                          final provider = context.read<TeamsProvider>();
                          final success = await provider.leaveTeam(
                            widget.teamId,
                          );

                          // Fermer l'indicateur de chargement
                          if (context.mounted) {
                            Navigator.of(context).pop();

                            if (success) {
                              // Retourner à la page précédente
                              Navigator.of(context).pop();

                              // Afficher un message de succès
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Vous avez quitté l\'équipe "${widget.teamName}"',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              // Afficher un message d'erreur
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Erreur lors de la sortie de l\'équipe',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.roseDim,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.rose),
                          ),
                          child: Center(
                            child: Text(
                              'Quitter',
                              style: AppTypography.display(
                                color: AppColors.rose,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
