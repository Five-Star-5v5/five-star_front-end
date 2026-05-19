import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/teams_service.dart';
import '../theme/app_colors.dart';

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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.muted2),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commentaires reçus',
              style: GoogleFonts.syne(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
              username,
              style: GoogleFonts.dmSans(color: AppColors.muted2, fontSize: 11),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border2),
        ),
      ),
      body: comments.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline, color: AppColors.muted2.withValues(alpha: 0.4), size: 40),
                  const SizedBox(height: 12),
                  Text('Aucun commentaire', style: GoogleFonts.syne(color: AppColors.muted2, fontSize: 14, fontWeight: FontWeight.w600)),
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.isAbsent ? AppColors.rose.withValues(alpha: 0.3) : AppColors.border2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.border2,
              shape: BoxShape.circle,
              image: c.authorAvatarUrl != null
                  ? DecorationImage(image: NetworkImage(c.authorAvatarUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: c.authorAvatarUrl == null
                ? const Icon(Icons.person_outline, size: 18, color: AppColors.muted2)
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
                      style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white),
                    ),
                    const Spacer(),
                    if (c.isAbsent)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.rose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Absent', style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.rose)),
                      ),
                    Text(dateStr, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.muted2)),
                  ],
                ),
                if (c.content != null && c.content!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(c.content!, style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted2)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
