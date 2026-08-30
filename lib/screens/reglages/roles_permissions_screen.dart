import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

const _permissions = [
  'Voir',
  'Créer',
  'Modifier',
  'Supprimer',
  'Valider',
  'Exporter',
  'Gérer les membres',
  'Gérer les cotisations',
  'Gérer les événements',
  'Gérer les recettes',
  'Gérer les dépenses',
  'Gérer les rapports',
  'Inviter des utilisateurs',
  'Gérer les paramètres',
];

class _RolePermissions {
  final String label;
  final String description;
  final List<String> permissions;
  const _RolePermissions(
      {required this.label,
      required this.description,
      required this.permissions});
}

const _roles = [
  _RolePermissions(
    label: 'Propriétaire',
    description: "Contrôle total de l'espace.",
    permissions: _permissions,
  ),
  _RolePermissions(
    label: 'Administrateur',
    description: "Gestion globale de l'espace, sans pouvoir le supprimer.",
    permissions: [
      'Voir',
      'Créer',
      'Modifier',
      'Valider',
      'Exporter',
      'Gérer les membres',
      'Gérer les cotisations',
      'Gérer les événements',
      'Gérer les recettes',
      'Gérer les dépenses',
      'Gérer les rapports',
      'Inviter des utilisateurs',
      'Gérer les paramètres',
    ],
  ),
  _RolePermissions(
    label: 'Trésorier',
    description:
        'Gestion financière complète : recettes, dépenses, cotisations, rapports.',
    permissions: [
      'Voir',
      'Créer',
      'Modifier',
      'Valider',
      'Exporter',
      'Gérer les cotisations',
      'Gérer les recettes',
      'Gérer les dépenses',
      'Gérer les rapports',
    ],
  ),
  _RolePermissions(
    label: 'Responsable',
    description: 'Accès aux modules qui lui sont confiés.',
    permissions: [
      'Voir',
      'Créer',
      'Modifier',
      'Gérer les membres',
      'Gérer les événements',
    ],
  ),
  _RolePermissions(
    label: 'Membre',
    description: 'Accès limité à ses propres informations.',
    permissions: ['Voir'],
  ),
];

/// Page de référence, en lecture seule : ce que chaque rôle peut faire dans
/// l'espace. La barrière réelle reste la Row Level Security côté base ;
/// cette page ne fait qu'expliciter ce qu'elle applique déjà. Reprend
/// `/espace/[espaceId]/roles` de tresora-app (src/lib/data.ts : ROLES,
/// PERMISSIONS_LIST).
class RolesPermissionsScreen extends StatelessWidget {
  const RolesPermissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rôles et permissions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Chaque rôle donne accès à un ensemble précis d'actions, propre "
            'à cet espace.',
            style: TextStyle(color: AppColors.texteSecondaire),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            childAspectRatio: 4.2,
            children: [
              for (final r in _roles)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.carte,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.bordure),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(r.label,
                          style: AppFonts.heading(
                              fontSize: 16, color: AppColors.texteEncre)),
                      const SizedBox(height: 2),
                      Text(r.description,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.texteSecondaire)),
                      const SizedBox(height: 2),
                      Text(
                        '${r.permissions.length} permission${r.permissions.length > 1 ? 's' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.texteSecondaire),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('MATRICE DES PERMISSIONS',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.texteSecondaire,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.carte,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bordure),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Permission')),
                  for (final r in _roles) DataColumn(label: Text(r.label)),
                ],
                rows: [
                  for (final permission in _permissions)
                    DataRow(cells: [
                      DataCell(Text(permission)),
                      for (final r in _roles)
                        DataCell(Center(
                          child: Icon(
                            r.permissions.contains(permission)
                                ? Icons.check
                                : Icons.close,
                            size: 16,
                            color: r.permissions.contains(permission)
                                ? AppColors.palme
                                : AppColors.texteSecondaire.withValues(
                                    alpha: .3),
                          ),
                        )),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
