import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/cotisation.dart';
import '../../models/membre.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/role_gate.dart';
import 'membre_form_screen.dart';
import '../../utils/erreurs.dart';

/// Fiche d'un membre : coordonnées + historique financier (ses cotisations
/// et leur statut). Reprend `MembreDetail` de tresora-app
/// (src/components/membres/membre-detail.tsx), sans la carte membre/QR code
/// qui reste hors périmètre côté mobile.
class MembreDetailScreen extends ConsumerWidget {
  final Membre membre;

  const MembreDetailScreen({super.key, required this.membre});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cotisationsAsync = ref.watch(cotisationsStreamProvider);
    final paiementsAsync = ref.watch(paiementsEspaceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(membre.nomComplet),
        actions: [
          RoleGate(
            peutAcceder: (r) => r.peutGererMembres,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Modifier',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => MembreFormScreen(membre: membre)),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.graphite,
                child: Text(
                  membre.nomComplet.isNotEmpty
                      ? membre.nomComplet[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(membre.nomComplet,
                        style: AppFonts.heading(
                            fontSize: 20, color: AppColors.texteEncre)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (membre.fonction?.isNotEmpty == true)
                          Text(membre.fonction!,
                              style: const TextStyle(
                                  color: AppColors.texteSecondaire)),
                        Chip(
                          label: Text(membre.actif ? 'Actif' : 'Inactif'),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: membre.actif
                              ? AppColors.palme.withValues(alpha: .12)
                              : AppColors.texteSecondaire.withValues(alpha: .15),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('INFORMATIONS',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Ligne(
                      icone: Icons.phone_outlined,
                      texte: membre.telephone.isEmpty
                          ? 'Non renseigné'
                          : membre.telephone),
                  if (membre.email?.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    _Ligne(icone: Icons.mail_outline, texte: membre.email!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('HISTORIQUE FINANCIER',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          cotisationsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Erreur : ${messageErreur(e)}'),
            data: (cotisations) => paiementsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Erreur : ${messageErreur(e)}'),
              data: (paiements) => _HistoriqueFinancier(
                cotisations: cotisations,
                paiements: paiements,
                membre: membre,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  final IconData icone;
  final String texte;

  const _Ligne({required this.icone, required this.texte});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: AppColors.texteSecondaire),
        const SizedBox(width: 10),
        Expanded(child: Text(texte)),
      ],
    );
  }
}

class _HistoriqueFinancier extends StatelessWidget {
  final List<Cotisation> cotisations;
  final List<PaiementCotisation> paiements;
  final Membre membre;

  const _HistoriqueFinancier(
      {required this.cotisations,
      required this.paiements,
      required this.membre});

  @override
  Widget build(BuildContext context) {
    final cotisationsParId = {for (final c in cotisations) c.id: c};
    final lignes = <(Cotisation, PaiementCotisation)>[];
    for (final p in paiements) {
      if (p.membreId != membre.id) continue;
      final cotisation = cotisationsParId[p.cotisationId];
      if (cotisation != null) lignes.add((cotisation, p));
    }

    if (lignes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.carte,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.bordure),
        ),
        child: const Text('Aucune cotisation associée à ce membre.',
            style: TextStyle(color: AppColors.texteSecondaire)),
      );
    }

    return Column(
      children: [
        for (final (cotisation, paiement) in lignes) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.carte,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cotisation.nom,
                          style: AppFonts.heading(
                              fontSize: 13, color: AppColors.texteEncre)),
                      const SizedBox(height: 3),
                      Text(
                          '${formatMontant(paiement.montantPaye)} / ${formatMontant(paiement.montantDu)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.texteSecondaire)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _couleurStatutCarte(paiement.statut)
                        .withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(paiement.statut.libelle,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _couleurStatutCarte(paiement.statut))),
                ),
              ],
            ),
          ),
          if (cotisation != lignes.last.$1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Color _couleurStatutCarte(StatutPaiement statut) => switch (statut) {
        StatutPaiement.paye => AppColors.palme,
        StatutPaiement.exonere => AppColors.texteSecondaire,
        StatutPaiement.partiel => AppColors.or,
        StatutPaiement.enRetard => AppColors.terre,
        StatutPaiement.impaye => AppColors.terre,
      };
}
