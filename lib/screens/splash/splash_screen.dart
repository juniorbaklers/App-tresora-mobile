import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motif.dart';
import '../../main.dart';

/// Écran de démarrage : la pastille et le nom apparaissent, puis le motif
/// de tissage se "tisse" de gauche à droite — reprend l'identité déjà
/// utilisée sur l'écran de connexion (pastille indigo/église + "Trésora"),
/// juste animée. Bascule ensuite vers AuthGate sans laisser de route
/// intermédiaire dans la pile (retour arrière impossible vers le splash).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controleur = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final Animation<double> _apparitionPastille = CurvedAnimation(
    parent: _controleur,
    curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
  );
  late final Animation<double> _apparitionNom = CurvedAnimation(
    parent: _controleur,
    curve: const Interval(0.25, 0.5, curve: Curves.easeOut),
  );
  late final Animation<double> _tissageMotif = CurvedAnimation(
    parent: _controleur,
    curve: const Interval(0.45, 0.85, curve: Curves.easeInOut),
  );
  late final Animation<double> _disparition = CurvedAnimation(
    parent: _controleur,
    curve: const Interval(0.92, 1.0, curve: Curves.easeIn),
  );

  @override
  void initState() {
    super.initState();
    _controleur.addStatusListener((statut) {
      if (statut == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
    _controleur.forward();
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.indigoProfond,
      body: Center(
        child: AnimatedBuilder(
          animation: _controleur,
          builder: (context, _) {
            return Opacity(
              opacity: 1 - _disparition.value,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.7 + 0.3 * _apparitionPastille.value.clamp(0, 1),
                    child: Opacity(
                      opacity: _apparitionPastille.value.clamp(0, 1),
                      child: Container(
                        width: 76,
                        height: 76,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.or,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.church,
                            size: 38, color: AppColors.indigoProfond),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Opacity(
                    opacity: _apparitionNom.value.clamp(0, 1),
                    child: Transform.translate(
                      offset:
                          Offset(0, 8 * (1 - _apparitionNom.value.clamp(0, 1))),
                      child: Text(
                        'Trésora',
                        style: AppFonts.heading(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _tissageMotif.value.clamp(0, 1),
                      child: const SizedBox(
                        width: 140,
                        child:
                            BandeTissee(tonalite: Tonalite.mixte, epaisseur: 4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
