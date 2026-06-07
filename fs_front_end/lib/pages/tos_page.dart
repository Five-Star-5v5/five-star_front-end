import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class TosPage extends StatelessWidget {
  const TosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.card2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border2),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.muted2,
              size: 14,
            ),
          ),
        ),
        title: Text(
          "CONDITIONS D'UTILISATION",
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSection('PRÉAMBULE', _preambule),
          _buildArticle('ARTICLE 1 — DÉFINITIONS', _article1),
          _buildArticle('ARTICLE 2 — OBJET', _article2),
          _buildArticle('ARTICLE 3 — ACCEPTATION DES CGU', _article3),
          _buildArticle(
            "ARTICLE 4 — CONDITIONS D'ACCÈS ET INSCRIPTION",
            _article4,
          ),
          _buildArticle(
            'ARTICLE 5 — LIMITATION DE RESPONSABILITÉ — ACTIVITÉS SPORTIVES ET BLESSURES',
            _article5,
          ),
          _buildArticle(
            'ARTICLE 6 — LIMITATION DE RESPONSABILITÉ — DÉSISTEMENTS ET FRAIS ENGAGÉS',
            _article6,
          ),
          _buildArticle(
            'ARTICLE 7 — SYSTÈME DE DÉFIS ET VALIDATION DES SCORES',
            _article7,
          ),
          _buildArticle(
            'ARTICLE 8 — POSTES OUVERTS ET CANDIDATURES',
            _article8,
          ),
          _buildArticle(
            'ARTICLE 9 — SERVICES DE MESSAGERIE INSTANTANÉE',
            _article9,
          ),
          _buildArticle(
            'ARTICLE 10 — RÈGLES DE COMPORTEMENT ET OBLIGATIONS DES UTILISATEURS',
            _article10,
          ),
          _buildArticle(
            'ARTICLE 11 — PROTECTION DES DONNÉES PERSONNELLES',
            _article11,
          ),
          _buildArticle(
            'ARTICLE 12 — FONCTIONNALITÉ DE CARTOGRAPHIE',
            _article12,
          ),
          _buildArticle('ARTICLE 13 — PROPRIÉTÉ INTELLECTUELLE', _article13),
          _buildArticle('ARTICLE 14 — DISPONIBILITÉ DU SERVICE', _article14),
          _buildArticle('ARTICLE 15 — MODIFICATION DES CGU', _article15),
          _buildArticle('ARTICLE 16 — SUPPRESSION DU COMPTE', _article16),
          _buildArticle(
            'ARTICLE 17 — LOI APPLICABLE ET JURIDICTION COMPÉTENTE',
            _article17,
          ),
          _buildArticle('ARTICLE 18 — DISPOSITIONS DIVERSES', _article18),
          const SizedBox(height: 16),
          _buildContact(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Application KOBETA',
            style: GoogleFonts.syne(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.amber,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.1 — Entrée en vigueur : 19 mai 2026',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted2),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.amber,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: AppColors.border2),
        const SizedBox(height: 10),
        Text(
          content,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.muted2,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildArticle(String title, List<_TosSection> sections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.amber,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(height: 1, color: AppColors.border2),
        const SizedBox(height: 10),
        ...sections.map((s) => _buildTosSection(s)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTosSection(_TosSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.subtitle != null) ...[
          Text(
            section.subtitle!,
            style: GoogleFonts.syne(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Text(
          section.body,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            color: AppColors.muted2,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildContact() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border2),
      ),
      child: Column(
        children: [
          Text(
            'CONTACT',
            style: GoogleFonts.syne(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.amber,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'kobeta.fr@gmail.com',
            style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted2),
          ),
          const SizedBox(height: 10),
          Text(
            'CGU rédigées sur la base du droit français en vigueur — Code civil · Code de la consommation · LCEN 2004 · RGPD (UE) 2016/679 · Loi Informatique et Libertés 1978 modifiée · Code du sport · Code pénal · DSA (UE) 2022/2065',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppColors.muted,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TosSection {
  const _TosSection({this.subtitle, required this.body});
  final String? subtitle;
  final String body;
}

// ── Contenu ────────────────────────────────────────────────────────────────────

const _preambule =
    '''L'application mobile KOBETA, accessible sur les plateformes iOS et Android, est éditée et exploitée conjointement par deux personnes physiques agissant en qualité de co-éditeurs particuliers, ci-après désignés individuellement « l'Éditeur » ou collectivement « les Éditeurs » :

Co-éditeur 1 :
  • Nom et prénom : [Axel CO-ÉDITEUR 1]
  • Demeurant au : [ADRESSE CO-ÉDITEUR 1]
  • Contact : kobeta.fr@gmail.com

Co-éditeur 2 :
  • Nom et prénom : [Lilian CO-ÉDITEUR 2]
  • Demeurant au : [ADRESSE CO-ÉDITEUR 2]
  • Contact : kobeta.fr@gmail.com

Conformément aux dispositions de l'article 6, III, 2° de la loi n° 2004-575 du 21 juin 2004 pour la Confiance dans l'Économie Numérique (LCEN), les co-éditeurs ont choisi de préserver leur anonymat vis-à-vis du grand public, pour des raisons de protection de la vie privée. Leurs coordonnées complètes sont régulièrement transmises à l'hébergeur de l'application.

Hébergeur :
  • Amazon Web Services (AWS), Inc.
  • 410 Terry Avenue North, Seattle, WA 98109-5210, États-Unis
  • Contact : https://aws.amazon.com/fr/contact-us

Les images de profil et logos d'équipe sont stockés sur la plateforme tierce Cloudinary (Cloudinary Ltd, 3 Hame'ayan St., Tel Aviv, Israël), conformément à ses conditions d'utilisation accessibles sur www.cloudinary.com.

KOBETA est une plateforme d'intermédiation numérique au sens de l'article L. 111-7 du Code de la consommation. À ce titre, les co-éditeurs agissent en qualité d'hébergeur et d'intermédiaire technique au sens de la loi n° 2004-575 du 21 juin 2004 (LCEN) et du Règlement (UE) 2022/2065 du Parlement européen et du Conseil du 19 octobre 2022 relatif à un marché unique des services numériques (Digital Services Act — DSA).

Les co-éditeurs ne sont en aucun cas organisateurs, co-organisateurs ou superviseurs des activités sportives arrangées entre les utilisateurs via la plateforme.''';

const _article1 = [
  _TosSection(
    body:
        '''Au sens des présentes Conditions Générales d'Utilisation, on entend par :

  • « Application » : l'application mobile KOBETA, accessible sur iOS et Android, ainsi que tout site web associé.
  • « Les Éditeurs » : les deux co-éditeurs personnes physiques ayant développé et exploitant conjointement l'Application KOBETA, tels qu'identifiés au Préambule.
  • « Utilisateur » : toute personne physique qui crée un compte et utilise les services proposés par l'Application.
  • « Équipe » : groupe d'utilisateurs constitué sur la plateforme en vue de pratiquer une activité sportive.
  • « Match » : rencontre sportive organisée entre deux équipes à la suite d'une mise en relation effectuée via l'Application.
  • « Défi » : invitation formelle envoyée par une équipe à une autre équipe en vue de disputer un match, pouvant inclure une date, un lieu et un message proposés.
  • « Poste ouvert » (open slot) : annonce publiée par une équipe signalant un poste de joueur disponible, accessible à tout utilisateur souhaitant postuler.
  • « Candidature » : demande soumise par un utilisateur pour rejoindre une équipe via un poste ouvert, pouvant inclure un message de présentation.
  • « Annonce » : publication créée par un utilisateur afin de rechercher une équipe adverse ou un joueur pour compléter son équipe.
  • « Centre partenaire » : établissement sportif référencé dans l'Application via la fonctionnalité de cartographie.
  • « Message » : tout contenu textuel échangé entre utilisateurs via les fonctionnalités de messagerie instantanée de l'Application (chat d'équipe ou chat de match).
  • « Données personnelles » : toute information au sens de l'article 4 du Règlement (UE) 2016/679 du 27 avril 2016 (RGPD).''',
  ),
];

const _article2 = [
  _TosSection(
    body:
        '''Les présentes Conditions Générales d'Utilisation ont pour objet de définir les modalités et conditions dans lesquelles les Éditeurs mettent à disposition des utilisateurs les services de l'Application, ainsi que les droits et obligations respectifs des parties.

L'Application propose les services suivants :
  • La mise en relation entre équipes sportives amateurs souhaitant disputer un match, via un système de défi (« challenge »)
  • La mise en relation entre équipes et joueurs individuels souhaitant rejoindre une équipe, via un système de postes ouverts et de candidatures
  • Un service de messagerie instantanée entre membres d'une même équipe (chat d'équipe) et entre équipes adverses lors d'un match confirmé (chat de match)
  • Une fonctionnalité de cartographie permettant de localiser des centres sportifs à proximité
  • La création et la gestion de profils d'équipes, incluant le niveau de jeu, les préférences de créneaux et de localisation
  • Un système de validation et d'enregistrement des scores de matchs à l'issue des rencontres''',
  ),
];

const _article3 = [
  _TosSection(
    subtitle: '3.1 Modalités d\'acceptation',
    body:
        '''Conformément aux articles 1128 et suivants du Code civil relatifs à la formation du contrat, l'utilisation de l'Application est subordonnée à l'acceptation préalable, expresse et sans réserve des présentes CGU.

Cette acceptation est matérialisée par le cochage de la case « J'ai lu et j'accepte les Conditions Générales d'Utilisation » lors de la création du compte. Cette action vaut signature électronique au sens de l'article 1366 du Code civil et engage l'utilisateur de manière ferme et définitive.''',
  ),
  _TosSection(
    subtitle: '3.2 Opposabilité',
    body:
        'Les CGU acceptées sont conservées par les Éditeurs et peuvent être communiquées à l\'utilisateur sur demande. Elles constituent la loi des parties conformément à l\'article 1103 du Code civil.',
  ),
];

const _article4 = [
  _TosSection(
    subtitle: '4.1 Conditions d\'âge',
    body:
        'Conformément à l\'article 8 du RGPD et à l\'article 45 de la loi n° 78-17 du 6 janvier 1978 modifiée (Loi Informatique et Libertés), l\'accès à l\'Application est réservé aux personnes physiques âgées d\'au moins 18 ans. Toute inscription par une personne mineure est strictement interdite. Les Éditeurs ne sauraient être tenus responsables de la communication de fausses informations par un utilisateur concernant son âge.',
  ),
  _TosSection(
    subtitle: '4.2 Création du compte',
    body:
        'L\'utilisateur s\'engage à fournir des informations exactes, complètes et à jour lors de son inscription. Toute fausse déclaration engage la responsabilité exclusive de l\'utilisateur. Chaque utilisateur ne peut créer qu\'un seul compte personnel. La création de comptes multiples est strictement interdite et constitue un motif de suspension immédiate de l\'ensemble des comptes concernés.',
  ),
  _TosSection(
    subtitle: '4.3 Sécurité des identifiants',
    body:
        'L\'utilisateur est seul responsable de la confidentialité de ses identifiants de connexion. Toute utilisation du compte par un tiers sera présumée effectuée par l\'utilisateur lui-même. En cas de compromission de ses identifiants, l\'utilisateur s\'engage à en informer les Éditeurs sans délai à l\'adresse : kobeta.fr@gmail.com.',
  ),
];

const _article5 = [
  _TosSection(
    subtitle: '5.1 Qualification juridique du service',
    body:
        'Conformément à l\'article 6 de la loi n° 2004-575 du 21 juin 2004 (LCEN) et aux articles L. 111-7 et suivants du Code de la consommation, les Éditeurs interviennent exclusivement en qualité d\'intermédiaires techniques de mise en relation. Les Éditeurs n\'organisent pas les matchs, ne supervisent pas leur déroulement et ne sont parties à aucun accord conclu entre les équipes.',
  ),
  _TosSection(
    subtitle: '5.2 Exclusion de responsabilité pour les dommages corporels',
    body:
        '''En application de l'article 1242 du Code civil relatif à la responsabilité du fait des choses, et dans la mesure où les Éditeurs n'ont ni la garde, ni le contrôle des activités sportives pratiquées, les Éditeurs excluent expressément toute responsabilité pour tout accident, blessure, dommage corporel ou décès survenant :
  • Avant, pendant ou après un match arrangé via l'Application
  • Lors de déplacements vers ou depuis le lieu du match
  • Dans les locaux d'un centre sportif référencé dans l'Application
  • Dans tout autre contexte lié à l'utilisation des services de mise en relation''',
  ),
  _TosSection(
    subtitle: '5.3 Obligation de couverture assurantielle',
    body:
        'Chaque utilisateur reconnaît et accepte qu\'il pratique toute activité sportive sous sa seule et entière responsabilité. Il est expressément rappelé à chaque utilisateur qu\'il lui appartient, s\'il le juge utile, de souscrire une assurance individuelle accidents couvrant la pratique du football à 5 et du padel en dehors de tout cadre fédéral, conformément à l\'esprit des dispositions de la loi n° 84-610 du 16 juillet 1984 relative à l\'organisation et à la promotion des activités physiques et sportives, codifiée aux articles L. 321-1 et suivants du Code du sport. Les Éditeurs ne souscrivent aucune assurance pour le compte des utilisateurs et ne peuvent en aucun cas être considérés comme organisateurs d\'activités sportives au sens du Code du sport.',
  ),
];

const _article6 = [
  _TosSection(
    subtitle: '6.1 Nature des engagements entre utilisateurs',
    body:
        'Les accords conclus entre équipes via la plateforme, notamment concernant la tenue d\'un match ou la réservation d\'un terrain, constituent des engagements contractuels directs entre les utilisateurs, auxquels les Éditeurs sont tiers au sens de l\'article 1199 du Code civil.',
  ),
  _TosSection(
    subtitle: '6.2 Exclusion de responsabilité financière',
    body:
        '''Les Éditeurs ne perçoivent aucune somme au titre de la réservation de terrains et ne sont parties à aucun contrat de réservation conclu entre un utilisateur et un centre sportif. En conséquence, les Éditeurs ne sauraient être tenus responsables :
  • Des frais de réservation engagés par une équipe en cas de désistement de l'équipe adverse
  • De tout préjudice financier résultant de l'annulation, du report ou de la non-tenue d'un match
  • Des litiges financiers survenant entre équipes concernant le partage des frais de terrain''',
  ),
  _TosSection(
    subtitle: '6.3 Mécanismes de prévention des désistements',
    body:
        '''Sans que cela ne constitue une obligation de résultat de leur part, les Éditeurs s'engagent à mettre en œuvre les mécanismes suivants afin de limiter les désistements abusifs :
  • Un système d'évaluation et de notation des équipes basé sur leur fiabilité et le respect de leurs engagements
  • La mise en place d'indicateurs de fiabilité visibles sur les profils d'équipes
  • Des mesures de restriction pouvant aller jusqu'à la suspension du compte des équipes présentant un historique avéré de désistements répétés et abusifs

Ces mécanismes constituent des mesures de bonne pratique et ne sauraient engager la responsabilité contractuelle des Éditeurs en cas d'inefficacité.''',
  ),
];

const _article7 = [
  _TosSection(
    subtitle: '7.1 Mécanisme de défi',
    body:
        'L\'Application permet à toute équipe de lancer un défi à une autre équipe en vue de disputer un match. Le défi peut inclure une date, un lieu et un message proposés. L\'équipe sollicitée dispose de la faculté d\'accepter ou de refuser le défi. Les Éditeurs ne sont pas parties à cet accord et n\'interviennent pas dans la négociation de ses conditions.\n\nL\'acceptation d\'un défi ouvre l\'accès à un espace de messagerie dédié entre les deux équipes conformément à l\'article 9 des présentes CGU.',
  ),
  _TosSection(
    subtitle: '7.2 Système de validation mutuelle des scores',
    body:
        'A l\'issue d\'un match, chaque équipe est invitée à soumettre indépendamment le score de la rencontre. Le score est validé lorsque les deux équipes soumettent des résultats identiques.\n\nEn cas de divergence entre les scores soumis par les deux équipes, le match est automatiquement déclaré nul (0-0). Les Éditeurs n\'interviennent pas dans la résolution des litiges de score et déclinent toute responsabilité quant à l\'exactitude des scores enregistrés.',
  ),
  _TosSection(
    subtitle: '7.3 Historique et conservation des scores',
    body:
        'Les scores validés sont intégrés à l\'historique de l\'équipe et au profil des utilisateurs concernés. Ils sont conservés indéfiniment, tant que le compte de l\'utilisateur est actif, afin d\'alimenter les statistiques de la plateforme. Ils sont supprimés dans un délai de 30 jours suivant la clôture du compte, conformément à l\'article 16 des présentes CGU.',
  ),
  _TosSection(
    subtitle: '7.4 Annulation d\'un défi accepté',
    body:
        'Un défi accepté peut être annulé par l\'une ou l\'autre des équipes via l\'Application. Cette annulation est prise en compte dans le système de notation de fiabilité prévu à l\'article 6.3 des présentes CGU.',
  ),
];

const _article8 = [
  _TosSection(
    subtitle: '8.1 Publication d\'un poste ouvert',
    body:
        'Toute équipe peut publier un ou plusieurs postes ouverts afin de recruter un joueur manquant. La publication d\'un poste ouvert mentionne obligatoirement le poste recherché (gardien, défenseur, milieu, attaquant ou libre) et peut inclure une description complémentaire. Le poste ouvert est visible par l\'ensemble des utilisateurs de la plateforme.\n\nL\'équipe peut clore un poste ouvert à tout moment, ce qui annule automatiquement l\'ensemble des candidatures en attente liées à ce poste.',
  ),
  _TosSection(
    subtitle: '8.2 Dépôt d\'une candidature',
    body:
        'Tout utilisateur peut postuler à un poste ouvert en soumettant une candidature, accompagnée d\'un message de présentation optionnel. Chaque utilisateur ne peut soumettre qu\'une seule candidature par poste ouvert. La candidature est transmise au responsable de l\'équipe concernée.\n\nL\'utilisateur reconnaît que les informations contenues dans son message de présentation sont partagées avec l\'équipe receveuse et engage sa responsabilité quant à leur exactitude.',
  ),
  _TosSection(
    subtitle: '8.3 Traitement des candidatures',
    body:
        'L\'équipe receveuse dispose de la faculté d\'accepter ou de refuser toute candidature, sans obligation de motivation. Les Éditeurs ne sont pas parties à ce processus de sélection et déclinent toute responsabilité concernant les décisions prises par les équipes.',
  ),
  _TosSection(
    subtitle: '8.4 Conservation des données de candidature',
    body:
        'Les données liées à une candidature (identité du candidat, message de présentation, statut) sont conservées jusqu\'à résolution de la candidature (acceptation ou refus), puis supprimées automatiquement. En cas de clôture d\'un poste ouvert par l\'équipe, les candidatures en attente associées sont immédiatement supprimées.\n\nL\'utilisateur qui a soumis une candidature peut l\'annuler à tout moment avant sa résolution, via les paramètres de l\'Application.',
  ),
];

const _article9 = [
  _TosSection(
    subtitle: '9.1 Nature des services de messagerie',
    body:
        '''L'Application propose deux services de messagerie instantanée distincts :
  • Le chat d'équipe : espace de messagerie privé accessible aux seuls membres d'une équipe, permettant les échanges entre coéquipiers.
  • Le chat de match : espace de messagerie privé ouvert entre les deux équipes parties à un défi accepté, permettant la coordination logistique du match.''',
  ),
  _TosSection(
    subtitle: '9.2 Obligations des utilisateurs',
    body:
        'L\'utilisation des services de messagerie est soumise aux règles de comportement énoncées à l\'article 10 des présentes CGU. Tout message publié engage la responsabilité exclusive de son auteur. Les Éditeurs agissent en qualité d\'hébergeur au sens de l\'article 6 de la LCEN et du DSA ; ils ne contrôlent pas le contenu des messages avant leur publication.',
  ),
  _TosSection(
    subtitle: '9.3 Modération et accès aux messages',
    body:
        'Les Éditeurs se réservent le droit d\'accéder aux messages dans le cadre strict des opérations de modération faisant suite à un signalement d\'un utilisateur ou à une réquisition judiciaire. Cet accès est limité à la stricte nécessité et ne constitue pas une surveillance systématique des échanges.',
  ),
  _TosSection(
    subtitle: '9.4 Durée de conservation des messages',
    body:
        'Les messages échangés via les services de messagerie de l\'Application sont conservés pour une durée de dix (10) jours à compter de leur envoi, après quoi ils sont automatiquement et irrémédiablement supprimés des serveurs des Éditeurs.\n\nCette durée de conservation est réduite à néant en cas de clôture du compte de l\'utilisateur, conformément à l\'article 16 des présentes CGU. Les Éditeurs ne sauraient être tenus responsables de la perte de messages découlant de l\'expiration de ce délai de conservation.\n\nL\'utilisateur est invité à noter que ses échanges ne sont pas archivés à des fins personnelles. Il lui appartient de conserver lui-même les informations importantes échangées via la messagerie.',
  ),
];

const _article10 = [
  _TosSection(
    subtitle: '10.1 Obligations générales',
    body:
        'Conformément aux dispositions de la loi n° 2004-575 du 21 juin 2004 et du Règlement (UE) 2022/2065 (DSA), chaque utilisateur s\'engage à utiliser l\'Application de manière licite, loyale et dans le respect des droits des tiers.',
  ),
  _TosSection(
    subtitle: '10.2 Comportements interdits',
    body:
        '''Sont expressément interdits sur la plateforme, sous peine de suspension ou de suppression immédiate du compte :

Concernant les communications :
  • Tout propos injurieux, discriminatoire, raciste, sexiste, homophobe ou à caractère haineux au sens de la loi n° 72-546 du 1er juillet 1972 et de la loi n° 90-615 du 13 juillet 1990
  • Tout message constitutif de harcèlement moral au sens des articles 222-33-2 et suivants du Code pénal
  • Toute menace, intimidation ou tentative d'extorsion

Concernant les profils et annonces :
  • La publication de fausses informations concernant une équipe, un joueur ou un match
  • L'usurpation d'identité au sens de l'article 226-4-1 du Code pénal
  • La création de faux profils ou fausses équipes
  • La soumission de candidatures de mauvaise foi ou sans intention réelle de rejoindre l'équipe concernée
  • La soumission d'un score de match erroné intentionnellement

Concernant l'utilisation du service :
  • Toute utilisation de l'Application à des fins commerciales non autorisées par les Éditeurs
  • Toute tentative de contournement des systèmes techniques de la plateforme
  • La création de comptes multiples''',
  ),
  _TosSection(
    subtitle: '10.3 Signalement et modération',
    body:
        'Conformément aux obligations imposées aux plateformes par le DSA, les Éditeurs mettent en place un dispositif de signalement permettant à tout utilisateur de signaler un contenu ou un comportement contraire aux présentes CGU. Les Éditeurs s\'engagent à traiter les signalements dans un délai raisonnable.',
  ),
  _TosSection(
    subtitle: '10.4 Sanctions',
    body:
        'En cas de manquement aux présentes obligations, les Éditeurs se réservent le droit de procéder, sans préavis ni indemnité, à la suspension temporaire ou à la suppression définitive du compte de l\'utilisateur concerné. Cette décision ne saurait engager la responsabilité des Éditeurs à l\'égard de l\'utilisateur sanctionné.',
  ),
];

const _article11 = [
  _TosSection(
    subtitle: '11.1 Responsables du traitement',
    body:
        'Conformément au Règlement (UE) 2016/679 du 27 avril 2016 (RGPD) et à la loi n° 78-17 du 6 janvier 1978 modifiée (Loi Informatique et Libertés), les responsables conjoints du traitement des données personnelles sont les deux co-éditeurs de l\'Application, tels qu\'identifiés au Préambule.\n\nPour toute question relative à vos données personnelles : kobeta.fr@gmail.com',
  ),
  _TosSection(
    subtitle: '11.2 Données collectées et finalités',
    body:
        '''Les Éditeurs collectent et traitent les catégories de données suivantes :
  • Adresse email — Finalité : communications sur les nouveautés et avancées du projet — Base légale : consentement (art. 6.1.a RGPD)
  • Données d'utilisation anonymisées et agrégées — Finalité : amélioration technique de l'Application — Base légale : intérêt légitime (art. 6.1.f RGPD)
  • Données de profil (nom d'équipe, sport pratiqué, ville) — Finalité : fonctionnement du service de mise en relation — Base légale : exécution du contrat (art. 6.1.b RGPD)
  • Préférences de matching (niveau de jeu, créneaux préférés, villes préférées) — Finalité : amélioration de la pertinence des mises en relation — Base légale : exécution du contrat (art. 6.1.b RGPD)
  • Historique des matchs et scores validés — Finalité : affichage des statistiques et du profil sportif — Base légale : exécution du contrat (art. 6.1.b RGPD)
  • Images de profil et logos d'équipe — Finalité : identification visuelle sur la plateforme — Base légale : consentement (art. 6.1.a RGPD) — Stockées sur Cloudinary
  • Messages échangés via les services de messagerie — Finalité : fourniture du service de communication — Base légale : exécution du contrat (art. 6.1.b RGPD)
  • Messages de présentation dans le cadre des candidatures — Finalité : faciliter le recrutement entre équipes et joueurs — Base légale : exécution du contrat (art. 6.1.b RGPD)''',
  ),
  _TosSection(
    subtitle: '11.3 Engagement de confidentialité et de non-communication',
    body:
        '''Les Éditeurs prennent l'engagement ferme que les données personnelles collectées sont utilisées exclusivement pour les finalités décrites à l'article 11.2. En aucun cas ces données ne sont :
  • Vendues, cédées, louées ou échangées à titre onéreux ou gratuit à des tiers
  • Communiquées à des partenaires commerciaux à des fins publicitaires ou de prospection
  • Utilisées à des fins autres que celles pour lesquelles elles ont été collectées

Les données d'utilisation collectées à des fins d'amélioration de l'Application sont strictement anonymisées et agrégées avant tout traitement, de sorte qu'elles ne permettent l'identification d'aucun utilisateur.''',
  ),
  _TosSection(
    subtitle: '11.4 Durée de conservation',
    body:
        '''  • Données de compte et de profil : durée de l'activité du compte, puis suppression dans un délai de 30 jours suivant la clôture du compte
  • Adresse email à des fins de communication : jusqu'au retrait du consentement par l'utilisateur
  • Préférences de matching et historique des matchs : durée de l'activité du compte, puis suppression dans un délai de 30 jours suivant la clôture
  • Messages de messagerie instantanée : 10 jours à compter de l'envoi, puis suppression automatique
  • Messages de présentation (candidatures) : jusqu'à résolution de la candidature, puis suppression automatique
  • Images de profil et logos d'équipe (Cloudinary) : conservées indéfiniment sur les serveurs de Cloudinary. L'utilisateur souhaitant leur suppression devra en faire la demande expressément à kobeta.fr@gmail.com
  • Données d'utilisation anonymisées : durée indéterminée dans la mesure où elles ne constituent pas des données personnelles au sens du RGPD''',
  ),
  _TosSection(
    subtitle: '11.5 Droits des utilisateurs',
    body:
        '''Conformément aux articles 15 à 22 du RGPD, chaque utilisateur dispose des droits suivants :
  • Droit d'accès : obtenir confirmation que des données le concernant sont traitées et en obtenir une copie
  • Droit de rectification : faire corriger des données inexactes ou incomplètes
  • Droit à l'effacement (droit à l'oubli) : obtenir la suppression de ses données dans les cas prévus par l'article 17 du RGPD
  • Droit à la portabilité : recevoir ses données dans un format structuré et lisible par machine
  • Droit d'opposition : s'opposer au traitement de ses données pour des motifs légitimes
  • Droit au retrait du consentement : retirer à tout moment son consentement aux communications, sans que cela affecte la licéité des traitements antérieurs

Pour exercer ces droits, l'utilisateur adresse sa demande à : kobeta.fr@gmail.com. Les Éditeurs s'engagent à répondre à toute demande dans un délai maximum d'un mois conformément à l'article 12 du RGPD.''',
  ),
  _TosSection(
    subtitle: '11.6 Droit de recours',
    body:
        'En cas de réponse insatisfaisante ou d\'absence de réponse, l\'utilisateur dispose du droit d\'introduire une réclamation auprès de la Commission Nationale de l\'Informatique et des Libertés (CNIL), 3 Place de Fontenoy, 75007 Paris — www.cnil.fr.',
  ),
];

const _article12 = [
  _TosSection(
    body:
        'L\'Application intègre une fonctionnalité de cartographie permettant de localiser des centres sportifs à proximité de l\'utilisateur. Cette fonctionnalité est fournie via l\'API Google Maps, soumise aux conditions d\'utilisation de Google LLC.\n\nLes Éditeurs ne garantissent pas l\'exactitude, l\'exhaustivité ou la mise à jour des informations relatives aux centres référencés. Le référencement d\'un centre dans l\'Application ne vaut pas recommandation, partenariat commercial ou garantie de la qualité des installations. Les Éditeurs ne sont en aucun cas responsables des informations erronées affichées par le service de cartographie.\n\nLa localisation de l\'utilisateur n\'est utilisée qu\'avec son consentement explicite et uniquement pour afficher les centres à proximité. Elle n\'est pas stockée ni conservée par les Éditeurs.',
  ),
];

const _article13 = [
  _TosSection(
    subtitle: '13.1 Droits des Éditeurs',
    body:
        'Conformément aux articles L. 111-1 et suivants du Code de la propriété intellectuelle, l\'ensemble des éléments constituant l\'Application — notamment le code source, les algorithmes, l\'interface graphique, le logo, la marque KOBETA, les textes et les fonctionnalités — sont la propriété exclusive des Éditeurs et sont protégés par le droit d\'auteur.\n\nToute reproduction, représentation, modification, adaptation ou exploitation de ces éléments, sous quelque forme que ce soit, sans l\'autorisation préalable et écrite des Éditeurs, est strictement interdite et constitue une contrefaçon sanctionnée par les articles L. 335-2 et suivants du Code de la propriété intellectuelle.',
  ),
  _TosSection(
    subtitle: '13.2 Droits des utilisateurs sur leurs contenus',
    body:
        'L\'utilisateur conserve la propriété des contenus qu\'il publie sur la plateforme, y compris ses images de profil et logos d\'équipe. En publiant un contenu, il accorde aux Éditeurs une licence non exclusive, gratuite, mondiale et pour la durée du contrat, d\'utiliser, reproduire et afficher ledit contenu dans le cadre strict du fonctionnement du service.\n\nEn ce qui concerne les images stockées sur Cloudinary, l\'utilisateur autorise également le transfert de ladite licence au profit de Cloudinary Ltd, dans les seules limites nécessaires au stockage et à la diffusion technique des images au sein de l\'Application.',
  ),
];

const _article14 = [
  _TosSection(
    body:
        'Les Éditeurs s\'efforcent de maintenir l\'Application accessible 24 heures sur 24 et 7 jours sur 7. Toutefois, conformément au droit commun des obligations, les Éditeurs ne peuvent garantir une disponibilité sans interruption du service.\n\nLes Éditeurs se réservent le droit de suspendre l\'accès à l\'Application pour des opérations de maintenance, de mise à jour ou pour tout motif technique, sans préavis et sans que cela ouvre droit à une quelconque indemnisation au profit des utilisateurs.\n\nLes Éditeurs se réservent également le droit de faire évoluer, modifier ou interrompre définitivement tout ou partie des fonctionnalités du service, sous réserve d\'en informer les utilisateurs dans un délai raisonnable par notification dans l\'Application ou par email.',
  ),
];

const _article15 = [
  _TosSection(
    body:
        'Les Éditeurs se réservent le droit de modifier les présentes CGU à tout moment, notamment pour se conformer à toute évolution législative, réglementaire ou jurisprudentielle, ou pour faire évoluer leurs services.\n\nToute modification substantielle sera notifiée aux utilisateurs par email ou par notification dans l\'Application, avec un préavis minimum de 30 jours avant son entrée en vigueur. La poursuite de l\'utilisation de l\'Application après l\'entrée en vigueur des nouvelles CGU vaut acceptation de celles-ci. À défaut d\'acceptation, l\'utilisateur est libre de supprimer son compte.',
  ),
];

const _article16 = [
  _TosSection(
    body:
        'L\'utilisateur peut à tout moment demander la suppression de son compte en adressant une demande à kobeta.fr@gmail.com ou via les paramètres de l\'Application. La suppression du compte entraîne l\'effacement de l\'ensemble des données personnelles identifiantes dans un délai de 30 jours, à l\'exception des données dont la conservation est imposée par une obligation légale.\n\nLes images de profil et logos d\'équipe stockés sur Cloudinary ne sont pas automatiquement supprimés lors de la clôture du compte. L\'utilisateur souhaitant obtenir leur suppression doit en faire la demande expressément à kobeta.fr@gmail.com, qui la transmettra à Cloudinary dans les meilleurs délais.',
  ),
];

const _article17 = [
  _TosSection(
    body:
        'Les présentes CGU sont soumises au droit français.\n\nConformément aux articles L. 611-1 et suivants du Code de la consommation relatifs à la médiation de la consommation, en cas de litige relatif à l\'interprétation ou à l\'exécution des présentes CGU, les parties s\'engagent à rechercher une solution amiable avant tout recours judiciaire. À cet effet, l\'utilisateur peut adresser sa réclamation à kobeta.fr@gmail.com. Les Éditeurs s\'engagent à y répondre dans un délai de 30 jours.\n\nEn l\'absence de résolution amiable, tout litige sera soumis à la compétence des juridictions françaises compétentes, sous réserve des règles impératives de compétence applicables aux consommateurs.',
  ),
];

const _article18 = [
  _TosSection(
    body:
        '''Divisibilité. Si l'une des clauses des présentes CGU était déclarée nulle ou inapplicable par une décision de justice, les autres clauses demeureront pleinement en vigueur.

Non-renonciation. Le fait pour les Éditeurs de ne pas se prévaloir d'un manquement de l'utilisateur à l'une des obligations prévues aux présentes CGU ne saurait être interprété comme une renonciation à se prévaloir de ce manquement ultérieurement.

Intégralité. Les présentes CGU constituent l'intégralité de l'accord entre les Éditeurs et l'utilisateur concernant l'utilisation de l'Application et remplacent tout accord antérieur relatif au même objet.''',
  ),
];
