import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teams_service.dart';

const _acBg     = Color(0xFF0A0C10);
const _acCard   = Color(0xFF181A21);
const _acBorder = Color(0x21FFFFFF);
const _acRose   = Color(0xFFD4607A);
const _acWhite  = Color(0xFFF0F2F5);
const _acMuted  = Color(0x9EF0F2F5);

class AllCommentsPage extends StatelessWidget {
  final String username;
  final List<PlayerCommentData> comments;

  const AllCommentsPage({
    super.key,
    required this.username,
    required this.comments,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _acBg,
      appBar: AppBar(
        backgroundColor: _acCard,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _acMuted),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commentaires reçus',
              style: GoogleFonts.syne(color: _acWhite, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              username,
              style: GoogleFonts.dmSans(color: _acMuted, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _acBorder),
        ),
      ),
      body: comments.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, color: _acMuted.withValues(alpha: 0.4), size: 40),
                  const SizedBox(height: 12),
                  Text('Aucun commentaire', style: GoogleFonts.syne(color: _acMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: comments.length,
              itemBuilder: (_, i) => _CommentCard(comment: comments[i]),
            ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final PlayerCommentData comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final c = comment;
    final dateStr =
        '${c.createdAt.day.toString().padLeft(2, '0')}/${c.createdAt.month.toString().padLeft(2, '0')}/${c.createdAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _acCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.isAbsent ? _acRose.withValues(alpha: 0.3) : _acBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _acBorder,
              shape: BoxShape.circle,
              image: c.authorAvatarUrl != null
                  ? DecorationImage(image: NetworkImage(c.authorAvatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: c.authorAvatarUrl == null
                ? const Icon(Icons.person_outline, size: 18, color: _acMuted)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      c.authorUsername ?? 'Joueur',
                      style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: _acWhite),
                    ),
                    const Spacer(),
                    if (c.isAbsent)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _acRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Absent', style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700, color: _acRose)),
                      ),
                    Text(dateStr, style: GoogleFonts.dmSans(fontSize: 10, color: _acMuted)),
                  ],
                ),
                if (c.content != null && c.content!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(c.content!, style: GoogleFonts.dmSans(fontSize: 12, color: _acMuted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
